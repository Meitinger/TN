'use strict';

/* Copyright (C) 2015, Manuel Meitinger
* 
* This program is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 2 of the License, or
* (at your option) any later version.
* 
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
* 
* You should have received a copy of the GNU General Public License
* along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

// define errors
function ArgumentException(message, paramName) {
    this.name = 'ArgumentException';
    this.message = message || 'Der Wert liegt außerhalb des erwarteten Bereichs.';
    if (paramName)
        this.message += '\nParametername: ' + paramName;
    this.paramName = paramName;
    this.stack = (new Error()).stack;
}
ArgumentException.prototype = Object.create(Error.prototype);
ArgumentException.prototype.constructor = ArgumentException;
function InvalidDataException(message) {
    this.name = 'InvalidDataException';
    this.message = message || 'Ungültige Daten beim Decodieren gefunden.';
    this.stack = (new Error()).stack;
}
InvalidDataException.prototype = Object.create(Error.prototype);
InvalidDataException.prototype.constructor = InvalidDataException;
function InvalidOperationException(message) {
    this.name = 'InvalidOperationException';
    this.message = message || 'Der Vorgang ist aufgrund des aktuellen Zustands des Objekts ungültig.';
    this.stack = (new Error()).stack;
}
InvalidOperationException.prototype = Object.create(Error.prototype);
InvalidOperationException.prototype.constructor = InvalidOperationException;
function UnauthorizedAccessException(message) {
    this.name = 'UnauthorizedAccessException';
    this.message = message || 'Es wurde versucht, einen nicht autorisierten Vorgang auszuführen.';
    this.stack = (new Error()).stack;
}
UnauthorizedAccessException.prototype = Object.create(Error.prototype);
UnauthorizedAccessException.prototype.constructor = UnauthorizedAccessException;

// define angular module
angular.module('tn', ['ngHandsontable'])

// SQL states
.constant('SqlState', {
    PendingApproval: 0,
    Execute: 1,
    HasError: 2,
    Completed: 3,
    Aborted: 4,
    Failed: 5
})

// SQL service
.service('sql', function ($q, $http, SqlState) {
    var svc = this;

    // bindable fields
    this.commands = [];
    this.reviewCommands = false;

    // reader helper function
    var reader = function (args, forceSingleSet, parser) {
        if (!angular.isObject(args) || !angular.isString(args.description) || !angular.isString(args.command) || angular.isDefined(args.parameters) && !angular.isObject(args.parameters))
            throw new ArgumentException('Die Argumente für die Abfrage sind ungültig.', 'args');

        // create the deferred object
        var deferred = $q.defer();

        // create the http config object
        var config = {
            method: 'GET',
            url: 'sql.ashx',
            params: { q: args.command }
        };
        if (args.parameters) {
            // type-check and encode the parameters
            var encodedParameters = [];
            for (var name in args.parameters) {
                var value = args.parameters[name];
                switch (typeof value) {
                    case 'number':
                        value = value.toString();
                        break;
                    case 'boolean':
                        value = value ? '1' : '0';
                        break;
                    case 'string':
                        value = encodeURIComponent(value);
                        break;
                    default:
                        if (value !== null)
                            throw new ArgumentException('Die Abfrage hat ungültige Parameter.', 'args');
                        value = '';
                        break;
                }
                encodedParameters.push(encodeURIComponent(name) + '=' + encodeURIComponent(value));
            }
            // update the http config
            angular.extend(config, {
                method: 'POST',
                data: encodedParameters.join('&'),
                headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                transformRequest: angular.identity
            });
        }

        // store internal flags
        var state = SqlState.PendingApproval;
        var error = null;
        var lastExecuteTime = null;
        var allowError = !!args.allowError;
        var singleSet = forceSingleSet || !!args.singleSet;

        // query helper
        var execute = function () {
            // set the state and reset the error
            state = SqlState.Execute;
            error = null;
            lastExecuteTime = new Date();
            $http(config).then(
	            function (response) {
	                // parse the reponse data
	                var success = true;
	                var data = response.data;
	                try {
	                    // check if the response include records
	                    if (angular.isArray(data)) {
	                        // make sure the recordsets are valid
	                        data.forEach(function (value, key) {
	                            if (!angular.isObject(value) || !angular.isNumber(value.RecordsAffected) || !angular.isArray(value.Records))
	                                throw new InvalidDataException('Ungültiges Recorset.');
	                            value.Records.forEach(function (value, key) {
	                                if (!angular.isObject(value))
	                                    throw new InvalidDataException('Ungültiger Record.');
	                            });
	                        });
	                        // ensure a single record set if requested
	                        if (singleSet) {
	                            if (data.length != 1)
	                                throw new InvalidDataException('Kein oder mehrere Recordsets wurden zurückgegeben.');
	                            data = data[0];
	                        }
	                        // parse the data
	                        data = parser(data);
	                    }

	                    // check if the response is an error
	                    else if (angular.isObject(data)) {
	                        success = false;
	                        // ensure a complete error object
	                        if (!angular.isNumber(data.CommandNumber) || !angular.isString(data.Message))
	                            throw new InvalidDataException('Ein ungültiges oder unvollständiges Fehlerobjekt wurde zurückgegeben.');
	                        // check if this is a managed error
	                        var match = data.Message.match(/^(.*?)\s\[TN\](?:\[(.+?)\](?:\[(.+?)\])?)?$/);
	                        if (!match || !allowError) {
	                            state = SqlState.HasError;
	                            error = match ? match[1] : data.Message;
	                            return;
	                        }
	                        // replace the data with a proper error object
	                        data = {
	                            statement: data.CommandNumber,
	                            message: match[1],
	                            table: match[2],
	                            column: match[3]
	                        };
	                    }

	                    // otherwise throw an error
	                    else
	                        throw new InvalidDataException('Server sendete ungültige Daten.');
	                }
	                catch (e) {
	                    // handle invalid data or rethrow otherwise
	                    if (e instanceof InvalidDataException) {
	                        state = SqlState.HasError;
	                        error = e.message;
	                        return;
	                    }
	                    throw e;
	                }

	                // resolve or reject the promise
	                if (success) {
	                    state = SqlState.Completed;
	                    deferred.resolve(data);
	                } else {
	                    state = SqlState.Failed;
	                    deferred.reject(data);
	                }
	            },
	            function (response) {
	                // set the state and error
	                state = SqlState.HasError;
	                error = 'Übertragungsfehler: ' + response.statusText;
	            }
	        );
        };

        // push the command object
        svc.commands.push({
            description: args.description,
            sql: args.command.replace(/[^@]@(\w+)/g, function (match, name) { return match[0] + '\'' + args.parameters[name] + '\''; }),
            abortable: allowError,
            getState: function () { return state; },
            getError: function () { return error; },
            getLastExecuteTime: function () { return lastExecuteTime; },
            approve: function () {
                if (state != SqlState.PendingApproval)
                    throw new InvalidOperationException('Der Befehl ist nicht im Überprüfungsmodus.');
                execute();
            },
            retry: function () {
                if (state != SqlState.HasError)
                    throw new InvalidOperationException('Der Befehl kann nicht wiederholt werden.');
                execute();
            },
            abort: function () {
                if (state != SqlState.HasError || !allowError)
                    throw new InvalidOperationException('Der Befehl kann nicht abgebrochen werden.');
                state = SqlState.Aborted;
                deferred.reject({
                    statement: 0,
                    message: 'Der Vorgang wurde abgebrochen.',
                    table: null,
                    column: null
                });
            }
        });

        // execute the command if no review is necessary
        if (!svc.reviewCommands || !args.allowReview)
            execute();

        // return the promise
        return deferred.promise;
    };

    // member functions
    this.scalar = function (args) {
        return reader(args, true, function (data) {
            if (data.Records.length > 1)
                throw new InvalidDataException('Zu viele zurückgegebene Zeilen für einen Skalarwert.');
            if (data.Records.length == 0)
                return null;
            var keys = Object.keys(data.Records[0]);
            if (keys.length != 1)
                throw new InvalidDataException('Es muss genaue eine Spalte für einen Skalarwert abgefragt werden.');
            return data.Records[0][keys[0]];
        });
    };
    this.nonQuery = function (args) {
        return reader(args, true, function (data) {
            if (data.Records.length > 0)
                throw new InvalidDataException('Ein abfragefreier SQL-Befehl darf keine Zeilen zurckgeben.');
            return data.RecordsAffected;
        });
    };
    this.query = function (args) {
        return reader(args, true, function (data) {
            if (data.RecordsAffected > 0)
                throw new InvalidDataException('Eine Abfrage darf keine Zeilen ändern.');
            return data.Records;
        });
    };
    this.batch = function (args) {
        return reader(args, false, function (data) {
            var changeCase = function (rs) {
                return {
                    recordsAffected: rs.RecordsAffected,
                    records: rs.Records
                };
            };
            if (angular.isArray(data)) {
                data.forEach(function (value, key, obj) {
                    obj[key] = changeCase(value);
                });
            }
            else
                data = changeCase(data);
            return data;
        });
    };
})

// notification service
.service('notification', function ($http, $timeout, $q) {

    // define the global vars
    var nextNotificationId = 0;
    var notifications = {};
    var error = null;
    var lastEventId = -1;
    var lastSyncTime = null;
    var lastEventTime = null;
    var readyEvent = $q.defer();

    // define the query function
    var query = function () {
        $http({
            method: 'GET',
            url: 'notify.ashx',
            params: { lastEventId: lastEventId },
            timeout: 60000
        }).then(
            function (response) {
                // parse the data
                try {
                    var data = response.data;
                    if (!angular.isObject(data))
                        throw new InvalidDataException('Kein Ereignisobjekt empfangen.');
                    if (!angular.isNumber(data.LastEventId))
                        throw new InvalidDataException('Rückgabeobjekt enthält keine Ereignisnummer.');
                    if (data.LastEventId < 0)
                        throw new InvalidDataException('Die Ereignisnummer ist negativ.');
                    if (!angular.isObject(data.Events))
                        throw new InvalidDataException('Die Ereignissammlung ist ungültig.');
                    for (var sourceName in data.Events) {
                        var source = data.Events[sourceName];
                        if (!angular.isObject(source))
                            throw new InvalidDataException('Die Ereignisquelle ' + sourceName + ' ist kein Objekt.');
                        for (var id in source) {
                            if (!id.match(/^[1-9]\d*$/))
                                throw new InvalidDataException('ID ' + id + ' von Ereignisquelle ' + sourceName + ' ist nicht numerisch.');
                            var version = source[id];
                            if (version !== null && !(angular.isString(version) && version.match(/^0x[0-9A-F]{16}$/)))
                                throw new InvalidDataException('Version von Ereignis ' + id + ' in Quelle ' + sourceName + ' ist ungültig.');
                        }
                    }
                }
                catch (e) {
                    // handle invalid data or rethrow otherwise
                    if (e instanceof InvalidDataException) {
                        error = e.message;
                        $timeout(query, 30000);
                        return;
                    }
                    throw e;
                }

                // set the last event id and reset the error
                var first = lastEventId == -1;
                error = null;
                lastEventId = data.LastEventId;
                lastSyncTime = new Date();

                // notify any readiness listeners or update the event time
                if (first)
                    readyEvent.resolve();
                else
                    lastEventTime = new Date();

                // notify the listeners
                for (var notificationId in notifications)
                    notifications[notificationId].notify(data.Events);

                // requery
                query();
            },
			function (response) {
			    // there is a network error, try again soon
			    error = 'Übertragungsfehler: "' + response.statusText + '".';
			    $timeout(query, 10000);
			}
		);
    };

    // define the function object
    var notification = function (fn) {
        // check the input arguments
        if (!angular.isFunction(fn))
            throw new ArgumentException('Funktionswert erwartet.', 'fn');

        // get the next id and increment the counter
        var id = nextNotificationId++;

        // get the deferred object and set its promise's notify function
        var deferred = $q.defer();
        var promise = deferred.promise;
        promise.then(null, null, fn);

        // add the notifcation
        notifications[id] = deferred;

        // set the promise id and return id
        promise.$notificationId = id;
        return promise;
    }

    // define the cancellation method
    notification.cancel = function (promise) {
        if (promise && promise.$notificationId in notifications) {
            var deferred = notifications[promise.$notificationId];
            delete notifications[promise.$notificationId];
            deferred.reject('cancelled');
            return true;
        }
        return false;
    };

    // define the readiness callback function
    notification.ready = function (fn) {
        var promise = readyEvent.promise;
        promise.then(fn);
        return promise;
    };

    // define the status functions
    notification.getError = function () {
        return error;
    }
    notification.getLastSyncTime = function () {
        return lastSyncTime;
    }
    notification.getLastEventTime = function () {
        return lastEventTime;
    }

    // initialize and return the notification function object
    query();
    return notification;
})

// define the table factory
.factory('table', function ($q, sql, notification) {
    return function (name, filter) {
        // check the input arguments
        if (!angular.isString(name) || !name.match(/^\w+$/))
            throw new ArgumentException('Tabellenname muss ein einfacher Bezeichner sein.', 'name');
        if (angular.isDefined(filter) && (!angular.isString(filter) || filter.match(/^\s*WHERE(\s+|$)/i)))
            throw new ArgumentException('Der Filter muss eine Zeichenfolge ohne WHERE-Prefix sein.');

        // create the variables
        var nextNewRowId = -1;
        var changedIdsBeforeReady = {};
        var notificationPromise = null;
        var permissions = {};
        var columns = [];
        var rows = {};

        // define a method to index rows
        var indexAndCheckData = function (data) {
            var result = {};
            data.forEach(function (entry) {
                if (!angular.isNumber(entry.$id) || entry.$id < 0)
                    throw new InvalidDataException('Ungültige ID gefunden.');
                if (!angular.isString(entry.$version) || !entry.$version.match(/^0x[0-9A-F]{16}$/))
                    throw new InvalidDataException('Ungültige Version gefunden.');
                result[entry.$id] = entry;
            });
            return result;
        }

        var handleNotifications = function (queryCommand, changedIds) {
            // get all ids that have to be requeried
            var requeryIds = [];
            for (var id in changedIds) {
                var version = changedIds[id];
                if (version == null) {
                    // check if the row is present
                    if (id in rows)
                        requeryIds.push(id);
                }
                else {
                    // check if the version is newer or the row is missing
                    if (id in rows) {
                        if (version > rows[id].$version)
                            requeryIds.push(id);
                    }
                    else
                        requeryIds.push(id);
                }
            }

            // query the database if there are changed rows
            if (requeryIds.length > 0) {
                sql.query({
                    description: 'Geänderte Zeilen von Tabelle ' + name + ' abfragen',
                    command: queryCommand + (filter ? ' AND ' : '\nWHERE ') + 'ID IN (' + requeryIds.join(',') + ')'
                }).then(function (data) {
                    // merge the changed rows
                    data = indexAndCheckData(data);
                    requeryIds.forEach(function (id) {
                        if (id in data) {
                            // create inserted or replace updated rows
                            if (!(id in rows) || data[id].$version > rows[id].$version)
                                rows[id] = data[id];
                        }
                        else {
                            // remove deleted rows
                            if (id in rows)
                                delete rows[id];
                        }
                    });
                });
            }
        };

        // initialize the table when ready
        notification.ready(function () {
            // query the permissions
            sql.query({
                description: 'Berechtigungen an Tabelle ' + name + ' abfragen',
                command: 'SELECT\n' +
                         '  HAS_PERMS_BY_NAME(@Table,\'OBJECT\',\'INSERT\') AS allowNew,\n' +
                         '  HAS_PERMS_BY_NAME(@Table,\'OBJECT\',\'UPDATE\') AS allowEdit,\n' +
                         '  HAS_PERMS_BY_NAME(@Table,\'OBJECT\',\'DELETE\') AS allowDelete',
                parameters: { 'Table': 'dbo.' + name },
                allowError: true
            }).then(function (data) {
                // store the permissions
                permissions = data;
            });

            // query the columns definition
            sql.query({
                description: 'Spaltendefinition von Tabelle ' + name + ' abfragen',
                command: 'SELECT\n' +
                         '  c.column_id AS id,\n' +
                         '  c.name,\n' +
                         '  t.name AS type,\n' +
                         '  c.max_length AS maxLength,\n' +
                         '  c.precision,\n' +
                         '  c.scale,\n' +
                         '  CASE WHEN c.is_nullable = 1 THEN 0 ELSE 1 END AS required,\n' +
                         '  CASE WHEN HAS_PERMS_BY_NAME(@Table,\'OBJECT\',\'UPDATE\',c.name,\'COLUMN\') = 1 THEN 0 ELSE 1 END AS readOnly,\n' +
                         '  OBJECT_NAME(f.referenced_object_id) AS [references]\n' +
                         'FROM\n' +
                         '  sys.columns AS c\n' +
                         '  JOIN\n' +
                         '  sys.types AS t ON c.user_type_id = t.user_type_id\n' +
                         '  LEFT OUTER JOIN\n' +
                         '  sys.foreign_key_columns AS f ON f.parent_object_id = c.object_id AND f.parent_column_id = c.column_id\n' +
                         'WHERE\n' +
                         '  c.object_id = OBJECT_ID(@Table) AND\n' +
                         '  HAS_PERMS_BY_NAME(@Table,\'OBJECT\',\'SELECT\',c.name,\'COLUMN\') = 1 AND\n' +
                         '  c.is_computed = 0\n' +
                         'ORDER BY c.column_id',
                parameters: { 'Table': 'dbo.' + name }
            }).then(function (data) {
                // check and store the columns
                if (data.length == 0)
                    throw new UnauthorizedAccessException('Keine sichtbaren Spalten in Tabelle ' + name + '.');
                if (data[0].name != 'ID')
                    throw new InvalidDataException('Die erste sichtbare ' + name + '-Spalte ist nicht "ID".');
                if (data[data.length - 1].name != 'Version')
                    throw new InvalidDataException('Die letzte sichtbare ' + name + '-Spalte ist nicht "Version".');
                columns = data.slice(1, -1);

                // create the base command
                var queryCommand = 'SELECT ' + columns.map(function (column) { return column.name; }).join(', ') + ', ID AS [$id], Version AS [$version]\nFROM dbo.' + name;
                if (filter)
                    queryCommand += '\nWHERE (' + filter + ')';

                // register a notification for database events
                notificationPromise = notification(function (events) {
                    if (name in events) {
                        // handle the event now or queue them for later
                        if (changedIdsBeforeReady == null)
                            handleNotifications(queryCommand, events[name]);
                        else
                            angular.extend(changedIdsBeforeReady, events[name]);
                    }
                });

                // retrieve the rows
                sql.query({
                    description: (filter ? 'Gefilterte' : 'Alle') + ' Zeilen von Tabelle ' + name + ' abfragen',
                    command: queryCommand
                }).then(function (data) {
                    // set the rows and handle all queued events
                    rows = indexAndCheckData(data);
                    var changedIds = changedIdsBeforeReady;
                    changedIdsBeforeReady = null;
                    handleNotifications(queryCommand, changedIds);
                });
            });
        });

        // helper function for inserting, updating and deleting rows
        var rowAction = function (id, fn) {
            // check the id
            if (!angular.isNumber(id))
                throw new ArgumentException('Numerischer Wert erwartet.', 'id');

            // create the deferred object
            var deferred = $q.defer();

            // check if the row exists
            if (id in rows) {
                var row = rows[id];

                // make sure there is no other action and store this promise
                if (angular.isDefined(row.$action))
                    throw new InvalidOperationException('Es ist bereits ein Vorgang bei dieser Zeile aktiv.');
                row.$action = deferred.promise;
                row.$action['finally'](function () {
                    delete row.$action;
                });

                // run the action
                fn(rows[id], deferred);
            }
            else
                deferred.reject('Die angegebene Zeile existiert nicht oder wurde bereits gelöscht.');

            // return the promise
            return deferred.promise;
        }

        // return the table object
        return {
            getColumns: function () {
                return columns;
            },
            getPermissions: function () {
                return permissions;
            },
            getRows: function () {
                var result = [];
                for (var id in rows)
                    result.push(rows[id]);
                return result;
            },
            getRowById: function (id) {
                return rows[id];
            },
            newRow: function () {
                // create and add an empty row
                var row = {
                    $id: nextNewRowId--,
                    $version: '0x0000000000000000'
                };
                rows[row.$id] = row;
            },
            editRow: function (id) {
                return rowAction(id, function (row, deferred) {
                    var handleError = function (error) {
                        // store the error and reject the promise
                        row.$error = error;
                        deferred.reject(error.message);
                    };
                    if (row.$id < 0) {
                        // insert the new row
                        var columnsWithValue = columns.filter(function (column) { return column.name in row; });
                        var insertParameters = {};
                        columnsWithValue.forEach(function (column) { insertParameters[column.name] = row[column.name]; });
                        sql.batch({
                            description: 'Zeile in Tabelle ' + name + ' einfügen',
                            command: 'INSERT INTO dbo.' + name + ' (' + columnsWithValue.map(function (column) { return column.name; }).join(', ') + ')\nVALUES (' + columnsWithValue.map(function (column) { return '@' + column.name; }).join(', ') + ');\nSELECT @@IDENTITY AS [$id];',
                            parameters: insertParameters,
                            allowReview: true,
                            allowError: true
                        }).then(
                            function (batch) {
                                // check the batch result
                                if (batch.recordsAffected == 0)
                                    throw new InvalidOperationException('Die Zeile wurde trotz Erfolg nicht in die Datenbank geschrieben.');
                                if (batch.records.length == 0 || !angular.isNumeric(batch.records[0].$id))
                                    throw new InvalidDataException('Die Rückgabewert von @@IDENTITY ist ungültig.');

                                // update the id and index (if not already done by notify)
                                delete rows[row.$id];
                                row.$id = batch.records[0].$id;
                                if (!(row.$id in rows))
                                    rows[row.$id] = row;

                                // clear the error and resolve the promise
                                row.$error = null;
                                deferred.resolve(row);
                            },
                            handleError
                        );
                    }
                    else {
                        // update an existing row
                        var writableColumnsWithValue = columns.filter(function (column) { return !column.readOnly && column.name in row; });
                        var updateParameters = {
                            'ID': row.$id,
                            'Version': row.$version
                        }
                        writableColumnsWithValue.forEach(function (column) { updateParameters[column.name] = row[column.name]; });
                        sql.nonQuery({
                            description: 'Zeile in Tabelle ' + name + ' ändern',
                            command: 'UPDATE dbo.' + name + '\nSET ' + writableColumnsWithValue.map(function (column) { return column.name + ' = @' + column.name; }).join(', ') + '\nWHERE ID = @ID AND Version = @Version',
                            parameters: updateParameters,
                            allowReview: true,
                            allowError: true
                        }).then(
                            function (recordsAffected) {
                                if (recordsAffected != 0) {
                                    // clear the error and resolve the promise
                                    row.$error = null;
                                    deferred.resolve(row);
                                }
                                else
                                    deferred.reject('Die Zeile wurde bereits geändert oder gelöscht.');
                            },
                            handleError
                        );
                    }
                });
            },
            deleteRow: function (id) {
                return rowAction(id, function (row, deferred) {
                    if (row.$id < 0) {
                        // remove new lines immediatelly
                        delete rows[row.$id];
                        deferred.resolve(row);
                    }
                    else {
                        // remove the row from the database
                        sql.nonQuery({
                            description: 'Zeile von Tabelle ' + name + ' löschen',
                            command: 'DELETE FROM dbo.' + name + ' WHERE ID = @ID AND Version = @Version',
                            parameters: {
                                'ID': row.$id,
                                'Version': row.$version
                            },
                            allowReview: true,
                            allowError: true
                        }).then(
                            function (recordsAffected) {
                                // delete the row if successful or reject the promise
                                if (recordsAffected != 0) {
                                    delete rows[row.$id];
                                    deferred.resolve(row);
                                }
                                else
                                    deferred.reject('Die Zeile wurde geändert oder bereits gelöscht.');
                            },
                            function (error) {
                                deferred.reject(error.message);
                            }
                        );
                    }
                });
            }
        };
    };
})
.controller('LogController', function (sql, notification) {
    this.sql = sql;
    this.notification = notification;
    this.limit = 10;
    this.limitOptions = [10, 50, 100, 500, 1000];
    this.offset = 0;
})
.controller('MainController', function ($scope, $window, sql, table) {
    $scope.Math = $window.Math;

    this.bescheid = table('Einrichtung');
    this.test = 'init';
    this.exec = function () {
        sql.scalar({
            description: 'testabfrage',
            command: 'DECLARE @ts timestamp; SET @ts = @timestamp; SELECT @ts;',
            parameters: { 'timestamp': '0x1234567890ABCDEF' }
        }).then(function (scalar) {
            alert(scalar);
        });
    };
});
