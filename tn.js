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

/* jshint curly: true, forin: false, freeze: true, latedef: nofunc, undef: true, unused: true */
/* globals angular: false, Handsontable: false, UIkit: false */

// define errors
function ArgumentException(message, paramName) {
    this.name = 'ArgumentException';
    this.message = message || 'Der Wert liegt außerhalb des erwarteten Bereichs.';
    if (paramName) {
        this.message += '\nParametername: ' + paramName;
    }
    this.paramName = paramName;
}
ArgumentException.prototype = Object.create(Error.prototype);
ArgumentException.prototype.constructor = ArgumentException;
ArgumentException.check = function (arg, name, constructor, optional) {
    if (typeof name !== 'string') {
        throw new Error('ArgumentException: name is a ' + (typeof name));
    }
    // thanks to IE we have to allow objects as constructors as well :(
    if (typeof constructor !== 'function' && typeof constructor !== 'object') {
        throw new Error('ArgumentException: constructor is a ' + (typeof constructor));
    }
    if (arg === void 0) {
        if (optional) {
            return;
        }
        throw new ArgumentException('Es muss ein Wert angegeben werden.', name);
    }
    if (arg === null) {
        throw new ArgumentException('Der Wert darf nicht null sein.', name);
    }
    if (arg.constructor !== constructor) {
        var getName = function (fn) {
            if (!fn) {
                return '(ohne)';
            }
            if (typeof fn.name === 'string') {
                return fn.name;
            }
            var match = fn.toString().match(/^\s*function\s+(.*?)\s*\(/);
            return match ? match[1] : '(unbekannt)';
        };
        throw new ArgumentException('Der Wert ist vom Typ "' + getName(arg.constructor) + '", erwartet wurde "' + getName(constructor) + '".', name);
    }
};
function InvalidDataException(message) {
    this.name = 'InvalidDataException';
    this.message = message || 'Ungültige Daten beim Decodieren gefunden.';
}
InvalidDataException.prototype = Object.create(Error.prototype);
InvalidDataException.prototype.constructor = InvalidDataException;
function InvalidOperationException(message) {
    this.name = 'InvalidOperationException';
    this.message = message || 'Der Vorgang ist aufgrund des aktuellen Zustands des Objekts ungültig.';
}
InvalidOperationException.prototype = Object.create(Error.prototype);
InvalidOperationException.prototype.constructor = InvalidOperationException;
function UnauthorizedAccessException(message) {
    this.name = 'UnauthorizedAccessException';
    this.message = message || 'Es wurde versucht, einen nicht autorisierten Vorgang auszuführen.';
}
UnauthorizedAccessException.prototype = Object.create(Error.prototype);
UnauthorizedAccessException.prototype.constructor = UnauthorizedAccessException;
function ObjectDisposedException(objectName) {
    this.name = 'ObjectDisposedException';
    this.message = 'Auf das verworfene Objekt kann nicht zugegriffen werden.';
    if (objectName) {
        this.message += '\nObjektname: ' + objectName;
    }
    this.objectName = objectName;
}
ObjectDisposedException.prototype = Object.create(InvalidOperationException.prototype);
ObjectDisposedException.prototype.constructor = ObjectDisposedException;

Date.create = (function () {
    var setReplacement = function () {
        throw new InvalidOperationException('Das Datum ist gesperrt.');
    };
    var dates = {};
    return function () {
        // create the actual date
        var date;
        switch (arguments.length) {
            case 0:
                date = new Date();
                break;
            case 1:
                // if the ticks constructor is used check the cache immeditally
                if (typeof arguments[0] === 'number' && arguments[0] in dates) {
                    return dates[arguments[0]];
                }
                date = new Date(arguments[0]);
                break;
            case 2:
                date = new Date(arguments[0], arguments[1]);
                break;
            default:
                date = new Date(arguments[0], arguments[1], arguments[2], arguments[3] || 0, arguments[4] || 0, arguments[5] || 0, arguments[6] || 0);
                break;
        }

        // check if the date is in the cache
        var value = date.valueOf();
        if (value in dates) {
            return dates[value];
        }

        // lock and freeze the object
        date.setDate = setReplacement;
        date.setFullYear = setReplacement;
        date.setHours = setReplacement;
        date.setMilliseconds = setReplacement;
        date.setMinutes = setReplacement;
        date.setMonth = setReplacement;
        date.setSeconds = setReplacement;
        date.setTime = setReplacement;
        date.setUTCDate = setReplacement;
        date.setUTCFullYear = setReplacement;
        date.setUTCHours = setReplacement;
        date.setUTCMilliseconds = setReplacement;
        date.setUTCMinutes = setReplacement;
        date.setUTCMonth = setReplacement;
        date.setUTCSeconds = setReplacement;
        date.setYear = setReplacement;
        date = Object.freeze(date);

        // add the date to the cache and return it
        dates[value] = date;
        return date;
    };
})();

// function that reports an error
UIkit.modal.error = function (src, msg, trace) {
    UIkit.modal.error = function () { };
    UIkit.modal.blockUI(
        '<h1>Jo, des is\' hin...</h1>' +
        '<p>Es ist ein unerwarteter Fehler aufgetreten.<br/>Die Meldung lautet:</p>' +
        '<p><b>' + msg + '</b></p>' +
        '<hr/>' +
        '<p><b>Bitte <a href="mailto:administrator@aufbauwerk.com?subject=[tn]%20' + encodeURIComponent(src) + '&amp;body=' + encodeURIComponent(trace) + '">melden</a> Sie den Fehler und laden Sie die Seite <a href="javascript:location.reload(true);">neu</a>.'
    );
};

// unhandled exception handler
window.onerror = function (msg, url, line) {
    UIkit.modal.error('window', msg, msg + '\n   at ' + url + ':' + line);
};

// define angular module
angular.module('tn', [])

// error handler
.factory('$exceptionHandler', function () {
    return function (exception) {
        UIkit.modal.error('angular', exception.message, exception.stack);
    };
})

// SQL states
.constant('SqlState', {
    PendingApproval: 0,
    Execute: 1,
    HasError: 2,
    Completed: 3,
    Aborted: 4,
    Failed: 5
})

// DB roles
.constant('Roles', {
    JobCoaching: 'Integrationsassistenz',
    Coaching: 'Training',
    Management: 'Leitung',
    Accounting: 'Rechnungswesen',
    Administration: 'Sekretariat'
})

// foreign row lookup names
.constant('ReferenceLabels', {
    'Teilnehmer': function (row) { return row.Nachname + ', ' + row.Vorname; },
    'Zeitspanne_Austrittsgrund': function (row) { return row.Bezeichnung; },
    'Bescheid_Typ': function (row) { return row.Bezeichnung; },
    'Standort': function (row) { return row.Name + '\n' + row.Adresse; },
    'Standort_Bereich': function (row) { return row.Code + ' - ' + row.Bezeichnung; },
    'Praktikum_Kategorie': function (row) { return row.Bezeichnung; },
    'Einrichtung': function (row) { return row.Name; },
    'Leistungsart': function (row) { return row.Bezeichnung; },
    'Kostensatz': function (row) { return row.Bezeichnung; },
    'Einheit': function (row) { return row.Bezeichnung; },
    'Rechnung': function (row) { return row.$id + ' ' + row.Bezeichnung; }
})

// SQL service
.service('sql', function ($q, $http, SqlState) {
    var Promise = $q.defer().promise.constructor;
    var svc = this;

    // bindable fields
    svc.commands = [];
    svc.reviewCommands = false;

    // reader helper function
    var reader = function (args, forceSingleSet, parser) {
        var command;
        ArgumentException.check(args, 'args', Object);
        ArgumentException.check(args.description, 'args.description', String);
        ArgumentException.check(args.command, 'args.command', String);
        ArgumentException.check(args.parameters, 'args.parameters', Object, true);
        ArgumentException.check(args.cancelOn, 'args.cancelOn', Promise, true);

        // create the http config object
        var config = {
            method: 'POST',
            url: 'sql.ashx',
            params: { q: args.command, noCache: (new Date()).valueOf() },
            cache: false,
            headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
            transformRequest: angular.identity
        };
        if (args.parameters) {
            // type-check and encode the parameters
            var encodedParameters = [];
            for (var name in args.parameters) {
                var value = args.parameters[name];
                switch (typeof value) {
                    case 'number':
                        if (isNaN(value)) {
                            throw new ArgumentException('Ungültiger numerischer Wert.', 'args.parameters.' + name);
                        }
                        value = value.toString();
                        break;
                    case 'boolean':
                        value = value ? '1' : '0';
                        break;
                    case 'string':
                        break;
                    case 'object':
                        if (value instanceof Date) {
                            if (isNaN(value.valueOf())) {
                                throw new ArgumentException('Ungültiges Datum.', 'args.parameters.' + name);
                            }
                            value = (new Date(Date.UTC(value.getFullYear(), value.getMonth(), value.getDate(), value.getHours(), value.getMinutes(), value.getSeconds(), value.getMilliseconds()))).toISOString();
                            break;
                        }
                        if (value === null) {
                            value = '';
                            break;
                        }
                        throw new ArgumentException('Objekttyp nicht unterstützt.', 'args.parameters.' + name);
                    default:
                        throw new ArgumentException('Typ "' + typeof value + '" nicht unterstützt.', 'args.parameters.' + name);
                }
                encodedParameters.push(encodeURIComponent(name) + '=' + encodeURIComponent(value));
            }

            // update the http config
            config.data = encodedParameters.join('&');
        }

        // handle cancellations
        var cancelled = false;
        if (args.cancelOn) {
            config.timeout = args.cancelOn.then(function (reason) {
                cancelled = true;
                if (command.state < SqlState.Completed) {
                    command.state = SqlState.Aborted;
                    command.error = reason;
                }
            });
        }

        // store internal flags
        var deferred = $q.defer();
        var allowError = !!args.allowError;
        var singleSet = forceSingleSet || !!args.singleSet;

        // query helper
        var execute = function () {
            // set the state and reset the error
            command.state = SqlState.Execute;
            delete command.error;
            command.lastExecuteTime = new Date();
            $http(config).then(
                function (response) {
                    // ensure not cancelled
                    if (cancelled) {
                        return;
                    }

                    // check if the response include records
                    var data = response.data;
                    if (data == void 0) {
                        throw new InvalidDataException('Keine SQL-Daten empfangen.');
                    }
                    if (data.constructor === Array) {
                        // make sure the recordsets are valid
                        for (var i = data.length - 1; i >= 0; i--) {
                            var recordset = data[i];
                            if (recordset == void 0 || recordset.constructor !== Object) {
                                throw new InvalidDataException('Recorset #' + (i + 1) + ' ist ungültig.');
                            }
                            var recordsAffected = recordset.RecordsAffected;
                            if (recordsAffected == void 0 || recordsAffected.constructor !== Number) {
                                throw new InvalidDataException('Zeilenanzahl von Recorset #' + (i + 1) + ' ist ungültig.');
                            }
                            var records = recordset.Records;
                            if (records == void 0 || records.constructor !== Array) {
                                throw new InvalidDataException('Zeilen des Recorsets #' + (i + 1) + ' sind ungültig.');
                            }
                            var dateFields = recordset.DateFields;
                            if (dateFields == void 0 || dateFields.constructor !== Array) {
                                throw new InvalidDataException('Datumsfelder des Recorsets #' + (i + 1) + ' sind ungültig.');
                            }

                            // ensure the rows are objects and convert dates
                            for (var j = records.length - 1; j >= 0; j--) {
                                var record = records[j];
                                if (record == void 0 || record.constructor !== Object) {
                                    throw new InvalidDataException('Zeile ' + (j + 1) + ' des Recorsets #' + (i + 1) + ' ist ungültig.');
                                }
                                var dateMatch;
                                for (var k = dateFields.length - 1; k >= 0; k--) {
                                    var dateName = dateFields[k];
                                    var value = record[dateName];
                                    if (value !== null) {
                                        if (value == void 0 || value.constructor !== String || !(dateMatch = value.match(/^(\d\d\d\d)-(\d\d)-(\d\d)T(\d\d):(\d\d):(\d\d)\.(\d\d\d)Z$/))) {
                                            throw new InvalidDataException('Datum "' + dateName + '" in Zeile ' + (j + 1) + ' des Recorsets #' + (i + 1) + ' ist ungültig.');
                                        }
                                        record[dateName] = Date.create(Number(dateMatch[1]), Number(dateMatch[2]) - 1, Number(dateMatch[3]), Number(dateMatch[4]), Number(dateMatch[5]), Number(dateMatch[6]), Number(dateMatch[7]));
                                    }
                                }
                            }
                        }

                        // ensure a single record set if requested
                        if (singleSet) {
                            if (data.length !== 1) {
                                throw new InvalidDataException('Keine oder mehrere Recordsets wurden zurückgegeben.');
                            }
                            data = data[0];
                        }

                        // parse the data and resolve the promise
                        data = parser(data);
                        command.state = SqlState.Completed;
                        deferred.resolve(data);
                    }

                    // check if the response is an error
                    else if (data.constructor === Object) {
                        // ensure a complete error object
                        var commandNumber = data.CommandNumber;
                        if (commandNumber == void 0 || commandNumber.constructor !== Number) {
                            throw new InvalidDataException('Der Befehlsindex im Fehlerobjekt ist ungültig.');
                        }
                        var message = data.Message;
                        if (message == void 0 || message.constructor !== String) {
                            throw new InvalidDataException('Die Fehlermeldung im Fehlerobjekt ist ungültig.');
                        }

                        // check if this is a managed error
                        var errorMatch = message.match(/^(.*?)\s\[TN\](?:\[(.+?)\](?:\[(.+?)\])?)?/);
                        command.error = errorMatch ? ('Ungültige Daten: ' + errorMatch[1]) : ('Datenbankfehler: ' + message);
                        if (!errorMatch || !allowError) {
                            command.state = SqlState.HasError;
                            return;
                        }

                        // replace the data with a proper error object
                        data = {
                            statement: commandNumber,
                            message: errorMatch[1],
                            table: errorMatch[2],
                            column: errorMatch[3]
                        };

                        // reject the promise
                        command.state = SqlState.Failed;
                        deferred.reject(data);
                    }

                    // otherwise throw an error
                    else {
                        throw new InvalidDataException('Server sendete ungültige Daten.');
                    }
                },
                function (response) {
                    // ensure not cancelled
                    if (cancelled) {
                        return;
                    }

                    // set the state and error
                    command.state = SqlState.HasError;
                    command.error = 'Übertragungsfehler: ' + response.statusText;
                }
            );
        };

        // push the command object
        command = {
            description: args.description,
            sql: args.command.replace(/[^@]@(\w+)/g, function (match, name) { return match[0] + '\'' + args.parameters[name] + '\''; }),
            abortable: allowError,
            state: SqlState.PendingApproval,
            approve: function () {
                if (command.state !== SqlState.PendingApproval) {
                    throw new InvalidOperationException('Der Befehl ist nicht im Überprüfungsmodus.');
                }
                execute();
            },
            retry: function () {
                if (command.state !== SqlState.HasError) {
                    throw new InvalidOperationException('Der Befehl kann nicht wiederholt werden.');
                }
                execute();
            },
            abort: function () {
                if (command.state !== SqlState.HasError || !allowError) {
                    throw new InvalidOperationException('Der Befehl kann nicht abgebrochen werden.');
                }
                command.state = SqlState.Aborted;
                deferred.reject({
                    statement: 0,
                    message: 'Der Vorgang wurde abgebrochen.',
                    table: null,
                    column: null
                });
            }
        };
        svc.commands.push(command);

        // execute the command if no review is necessary
        if (!svc.reviewCommands || !args.allowReview) {
            execute();
        }

        // return the promise
        return deferred.promise;
    };

    // member functions
    svc.scalar = function (args) {
        return reader(args, true, function (data) {
            if (data.Records.length > 1) {
                throw new InvalidDataException('Zu viele zurückgegebene Zeilen für einen Skalarwert.');
            }
            if (data.Records.length === 0) {
                return null;
            }
            var keys = Object.keys(data.Records[0]);
            if (keys.length !== 1) {
                throw new InvalidDataException('Es muss genau eine Spalte für einen Skalarwert abgefragt werden.');
            }
            return data.Records[0][keys[0]];
        });
    };
    svc.nonQuery = function (args) {
        return reader(args, true, function (data) {
            if (data.Records.length > 0) {
                throw new InvalidDataException('Ein abfragefreier SQL-Befehl darf keine Zeilen zurückgeben.');
            }
            return data.RecordsAffected;
        });
    };
    svc.query = function (args) {
        return reader(args, true, function (data) {
            if (data.RecordsAffected > 0) {
                throw new InvalidDataException('Eine Abfrage darf keine Zeilen ändern.');
            }
            return data.Records;
        });
    };
    svc.batch = function (args) {
        return reader(args, false, angular.identity);
    };
})

// notification service
.service('notification', function ($http, $timeout, $q) {
    var Promise = $q.defer().promise.constructor;

    // define the global vars
    var nextNotificationId = 0;
    var notifications = {};
    var lastEventId = -1;
    var readyEvent = $q.defer();

    // define the function object
    var notification = function (fn) {
        ArgumentException.check(fn, 'fn', Function);

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
    };

    // define the cancellation method
    notification.cancel = function (promise) {
        ArgumentException.check(promise, 'promise', Promise);

        if (promise.$notificationId in notifications) {
            notifications[promise.$notificationId].reject('cancelled');
            delete notifications[promise.$notificationId];
            return true;
        }
        return false;
    };

    // define the readiness callback function
    notification.ready = function (fn) {
        ArgumentException.check(fn, 'fn', Function, true);

        // set the callback if given and return the promise
        if (fn) {
            readyEvent.promise.then(fn);
        }
        return readyEvent.promise;
    };

    // define the query function
    var query = function () {
        $http({
            method: 'GET',
            url: 'notify.ashx',
            params: { lastEventId: lastEventId, noCache: (new Date()).valueOf() },
            cache: false,
            timeout: 60000
        }).then(
            function (response) {
                // check the data
                var data = response.data;
                if (data == void 0 || data.constructor !== Object) {
                    throw new InvalidDataException('Ungültiges Ereignisobjekt empfangen.');
                }
                var newLastEventId = data.LastEventId;
                if (newLastEventId == void 0 || newLastEventId.constructor !== Number || newLastEventId < 0) {
                    throw new InvalidDataException('Ungültige Ereignisnummer empfangen.');
                }
                var events = data.Events;
                if (events == void 0 || events.constructor !== Object) {
                    throw new InvalidDataException('Die Ereignissammlung ist ungültig.');
                }
                var hasEvents = false;
                for (var sourceName in events) {
                    var source = events[sourceName];
                    if (source == void 0 || source.constructor !== Object) {
                        throw new InvalidDataException('Die Ereignisquelle "' + sourceName + '" ist kein Objekt.');
                    }
                    hasEvents = true;
                    for (var id in source) {
                        if (!id.match(/^[1-9]\d*$/)) {
                            throw new InvalidDataException('ID "' + id + '" von Ereignisquelle "' + sourceName + '" ist nicht numerisch.');
                        }
                        var version = source[id];
                        if (version !== null && (version == void 0 || version.constructor !== String || !version.match(/^0x[0-9A-F]{16}$/))) {
                            throw new InvalidDataException('Version von Ereignis #' + id + ' in Quelle "' + sourceName + '" ist ungültig.');
                        }
                    }
                }

                // set the last event id and reset the error
                var first = lastEventId === -1;
                delete notification.error;
                lastEventId = newLastEventId;
                notification.lastSyncTime = new Date();

                // notify any readiness listeners and update the event time
                if (first) {
                    readyEvent.resolve();
                }
                if (hasEvents) {
                    notification.lastEventTime = new Date();
                }

                // notify the listeners
                for (var notificationId in notifications) {
                    notifications[notificationId].notify(events);
                }

                // requery
                query();
            },
            function (response) {
                // there is a network error, try again soon
                notification.error = response.statusText || 'Zeitüberschreitung';
                $timeout(query, 10000);
            }
        );
    };

    // initialize and return the notification function object
    query();
    return notification;
})

// define the table factory
.factory('Table', function ($q, $rootScope, sql, notification) {
    return function Table(name, filter) {
        var table = this;

        ArgumentException.check(name, 'name', String);
        ArgumentException.check(filter, 'filter', String, true);

        // check the input arguments
        if (!name.match(/^\w+$/)) {
            throw new ArgumentException('Der Tabellenname muss ein einfacher Bezeichner sein.', 'name');
        }
        if (filter && filter.match(/^\s*WHERE(\s+|$)/i)) {
            throw new ArgumentException('Der Filter darf keinen WHERE-Prefix enthalten.', 'filter');
        }

        // create the variables
        var disposed = false;
        var disposeDeferred = $q.defer();
        var disposePromise = disposeDeferred.promise;
        var nextNewRowId = -1;
        var notificationPromise = null;
        var rowIndex = {};
        var eventsBeforeReady = {};
        var readyEvent = $q.defer();
        var changeListeners = [];

        // wrap a function around a dispose checker
        var throwIfDisposed = function (fn) {
            return function () {
                if (disposed) {
                    throw new ObjectDisposedException('Tabelle ' + name);
                }
                return fn.apply(this, arguments);
            };
        };

        // ensure the columns have been queried
        var throwIfNoColumns = function (fn) {
            return function () {
                if (table.columns.length === 0) {
                    throw new InvalidOperationException('Die Spalten wurden noch nicht abgefragt.');
                }
                return fn.apply(this, arguments);
            };
        };

        // call all row listeners asynchronously
        var notifyAsync = function (oldRow, newRow) {
            var callback = function (fn) {
                $rootScope.$evalAsync(function () {
                    fn(table, oldRow, newRow);
                });
            };
            for (var i = changeListeners.length - 1; i >= 0; i--) {
                callback(changeListeners[i]);
            }
        };

        // makes sure the row exists and returns its index
        var indexOfRow = function (row) {
            for (var i = table.rows.length - 1; i >= 0; i--) {
                if (table.rows[i] === row) {
                    return i;
                }
            }
            throw new InvalidOperationException('Eine Zeile wurde außerhalb gelöscht.');
        };

        // define a method to index rows
        var indexAndCheckData = function (data, requeryIds) {
            for (var i = data.length - 1; i >= 0; i--) {
                var oldRow = null;
                var newRow = data[i];

                // ensure the entry is valid
                var id = newRow.$id;
                if (id == void 0 || id.constructor !== Number || id < 1) {
                    throw new InvalidDataException('Ungültige ID gefunden.');
                }
                var version = newRow.$version;
                if (version == void 0 || version.constructor !== String || !version.match(/^0x[0-9A-F]{16}$/)) {
                    throw new InvalidDataException('Ungültige Version gefunden.');
                }
                var clonedEntry = {};
                var columns = table.columns;
                for (var j = columns.length - 1; j >= 0; j--) {
                    var columnName = columns[j].name;
                    var value = newRow[columnName];
                    if (value === void 0) {
                        throw new InvalidDataException('Der Wert für Spalte "' + columnName + '" von Tabelle "' + name + '" wurde nicht zurückgegeben.');
                    }
                    clonedEntry[columnName] = value;
                }
                newRow.$orig = clonedEntry;

                // add the first rows or merge changed rows
                if (requeryIds === null) {
                    if (id in rowIndex) {
                        throw new InvalidDataException('Doppelte ID #' + id + ' gefunden.');
                    }
                    table.rows.push(newRow);
                    rowIndex[id] = newRow;
                }
                else {
                    // find and remove the id
                    var foundId = false;
                    for (var k = requeryIds.length - 1; k >= 0; k--) {
                        if (requeryIds[k] === id) {
                            foundId = true;
                            requeryIds.splice(k, 1);
                            break;
                        }
                    }
                    if (!foundId) {
                        throw new InvalidDataException('Doppelte oder nicht abgefragte ID #' + id + ' gefunden.');
                    }

                    // create an inserted or replace an updated row
                    if (id in rowIndex) {
                        oldRow = rowIndex[id];
                        if (newRow.$version <= oldRow.$version) {
                            continue;
                        }
                        table.rows[indexOfRow(oldRow)] = newRow;
                        rowIndex[id] = newRow;
                    }
                    else {
                        table.rows.push(newRow);
                        rowIndex[id] = newRow;
                    }
                }

                // notify the listeners
                notifyAsync(oldRow, newRow);
            }

            // remove all deleted rows
            if (requeryIds !== null) {
                for (var l = requeryIds.length - 1; l >= 0; l--) {
                    var deletedId = requeryIds[l];
                    if (deletedId in rowIndex) {
                        var deletedRow = rowIndex[deletedId];
                        table.rows.splice(indexOfRow(deletedRow), 1);
                        delete rowIndex[deletedId];
                        notifyAsync(deletedRow, null);
                    }
                }
            }
        };

        // helper function to update changed rows
        var handleNotifications = function (queryCommand, changedIds) {
            // get all ids that have to be requeried
            var requeryIds = [];
            for (var id in changedIds) {
                var version = changedIds[id];
                if (version === null) {
                    // check if the row is present
                    if (id in rowIndex) {
                        requeryIds.push(Number(id));
                    }
                }
                else {
                    // check if the version is newer or the row is missing
                    if (!(id in rowIndex) || version > rowIndex[id].$version) {
                        requeryIds.push(Number(id));
                    }
                }
            }

            // query the database if there are changed rows
            if (requeryIds.length > 0) {
                sql.query({
                    description: 'Geänderte Zeilen von Tabelle ' + name + ' abfragen',
                    command: queryCommand + (filter ? ' AND ' : '\nWHERE ') + 'ID IN (' + requeryIds.join(',') + ')',
                    cancelOn: disposePromise
                }).then(function (data) {
                    // merge the changed rows
                    indexAndCheckData(data, requeryIds);
                });
            }
        };

        // helper function for inserting, updating and deleting rows
        var rowAction = function (row, fn, setError) {
            ArgumentException.check(row, 'row', Object);
            ArgumentException.check(row.$id, 'row.$id', Number);

            // check the row
            if (!(row.$id in rowIndex) || rowIndex[row.$id] !== row) {
                throw new ArgumentException('Die Zeile #' + row.$id + ' befindet sich nicht (mehr) in der Tabelle "' + name + '".', 'row');
            }

            // create the deferred object
            var deferred = $q.defer();

            // make sure there is no other action and store this promise
            if (row.$action) {
                throw new InvalidOperationException('Es ist bereits ein Vorgang bei Zeile #' + row.$id + ' in Tabelle "' + name + '" aktiv.');
            }
            row.$action = deferred.promise;

            // create the callbacks
            var succeed = function () {
                if (setError) {
                    delete row.$error;
                }
                delete row.$action;
                deferred.resolve(row);
            };
            var fail = function (error) {
                if (setError) {
                    row.$error = error;
                }
                delete row.$action;
                deferred.reject(error.message);
            };

            // run the action and return the promise
            fn(row, succeed, fail);
            return deferred.promise;
        };

        // check the value of a column
        var checkColumnValue = function (column, value, fail) {
            // helper function
            var failWithMessage = function (message) {
                fail({
                    statement: 0,
                    message: message,
                    table: name,
                    column: column.name
                });
            };

            // check for NULL
            if (value === null) {
                if (column.required) {
                    failWithMessage('Die Spalte "' + column.name + '" muss einen Wert haben.');
                    return false;
                }
                return true;
            }

            // get the required type and range
            var type = null;
            var checkNaN = false;
            var range = null;
            var maxLength = null;
            switch (column.type) {
                case 'int':
                    type = Number;
                    checkNaN = true;
                    range = [-2147483648, 2147483647];
                    break;
                case 'char':
                case 'varchar':
                    type = String;
                    maxLength = column.maxLength;
                    break;
                case 'nchar':
                case 'nvarchar':
                    type = String;
                    maxLength = column.maxLength / 2;
                    break;
                case 'datetime':
                    type = Date;
                    checkNaN = true;
                    range = [new Date(1753, 0, 1, 0, 0, 0, 0), new Date(9999, 11, 31, 23, 59, 59, 997)];
                    break;
                case 'smalldatetime':
                    type = Date;
                    checkNaN = true;
                    range = [new Date(1900, 0, 1, 0, 0, 0, 0), new Date(2079, 5, 6, 23, 59, 59, 0)];
                    break;
                case 'decimal':
                    type = Number;
                    checkNaN = true;
                    var pow = Math.pow(10, (column.precision - column.scale));
                    range = [Math.min(-1, -pow + 1), Math.max(1, pow - 1)];
                    break;
                case 'money':
                    type = Number;
                    checkNaN = true;
                    range = [-922337203685477.5808, 922337203685477.5807];
                    break;
                case 'bit':
                    type = Boolean;
                    break;
                default:
                    failWithMessage('Die Spalte "' + column.name + '" kann nicht eingefügt oder aktualisiert werden da ihr Typ "' + column.type + '" wird nicht unterstützt.');
                    return false;
            }

            // check the type
            if (value.constructor !== type) {
                failWithMessage('Der Javascript-Typ der Spalte "' + column.name + '" ist nicht geeignet für den SQL-Typ.');
                return false;
            }

            // check NaN
            if (checkNaN && isNaN(value.valueOf())) {
                failWithMessage('Der Wert in Spalte "' + column.name + '" ist ungültig.');
                return false;
            }

            // check the length
            if (maxLength !== null && value.length > maxLength) {
                failWithMessage('Die Länge des Wertes in Spalte "' + column.name + '" überschreitet das Maximum von ' + maxLength + '.');
                return false;
            }

            // check the range
            if (range !== null) {
                if (value < range[0]) {
                    failWithMessage('Der Wert der Spalte "' + column.name + '" liegt unterhalb des Minimums ' + range[0].toLocaleString() + '.');
                    return false;
                }
                if (value > range[1]) {
                    failWithMessage('Der Wert der Spalte "' + column.name + '" liegt oberhalb des Maximums ' + range[1].toLocaleString() + '.');
                    return false;
                }
            }
            return true;
        };

        // insert a new row
        var insertRow = function (row, succeed, fail) {
            // get all columns that have a value set
            var columnsWithValue = [];
            var insertParameters = {};
            for (var i = table.columns.length - 1; i >= 0; i--) {
                var column = table.columns[i];
                var columnName = column.name;
                var value = row[columnName];
                if (value === void 0) {
                    if (!column.hasDefault) {
                        // don't allow missing columns without default values
                        fail({
                            statement: 0,
                            message: 'Spalte "' + columnName + '" muss definiert sein.',
                            table: name,
                            column: columnName
                        });
                        return;
                    }
                }
                else {
                    if (!checkColumnValue(column, value, fail)) {
                        return;
                    }
                    insertParameters[columnName] = value;
                    columnsWithValue.push(columnName);
                }
            }
            sql.batch({
                description: 'Zeile in Tabelle ' + name + ' einfügen',
                command: 'INSERT INTO dbo.' + name + ' ' + (columnsWithValue.length === 0 ? 'DEFAULT VALUES' : ('(' + columnsWithValue.join(', ') + ')\n' +
                         'VALUES (@' + columnsWithValue.join(', @') + ')')) + '\n' +
                         'IF @@ERROR = 0\n' +
                         'BEGIN\n' +
                         '    SELECT SCOPE_IDENTITY() AS [$id]\n' +
                         (filter ? (
                         '    IF NOT EXISTS (SELECT * FROM dbo.' + name + ' WHERE ID = SCOPE_IDENTITY() AND (' + filter + ')) RAISERROR(\'Der Eintrag entspricht nicht dem Tabellenfilter. [TN][' + name + ']\', 16, 1)\n'
                         ) : '') +
                         'END',
                parameters: insertParameters,
                singleSet: true,
                allowReview: true,
                allowError: true,
                cancelOn: disposePromise
            }).then(
                function (batch) {
                    // check the batch result
                    if (batch.RecordsAffected === 0) {
                        throw new InvalidOperationException('Die Zeile wurde trotz Erfolg nicht in die Datenbank geschrieben.');
                    }
                    if (batch.Records.length === 0) {
                        throw new InvalidDataException('@@SCOPE_IDENTITY hat keinen Wert zurückgegeben.');
                    }
                    var id = batch.Records[0].$id;
                    if (id == void 0 || id.constructor !== Number || id < 1) {
                        throw new InvalidDataException('Der Rückgabewert von @@SCOPE_IDENTITY ist ungültig.');
                    }

                    // delete the temporary row and remember its index
                    var oldIndex = indexOfRow(row);
                    table.rows.splice(oldIndex, 1);
                    delete rowIndex[row.$id];
                    notifyAsync(row, null);

                    // update and reindex the row (if not done by an event already)
                    row.$id = id;
                    for (var i = columnsWithValue.length - 1; i >= 0; i--) {
                        var columnName = columnsWithValue[i];
                        row.$orig[columnName] = row[columnName];
                    }
                    if (!(row.$id in rowIndex)) {
                        table.rows.splice(oldIndex, 0, row);
                        rowIndex[row.$id] = row;
                        notifyAsync(null, row);
                    }

                    // finish
                    succeed();
                },
                fail
            );
        };

        // update an existing row
        var updateRow = function (row, succeed, fail) {
            // get all changed columns
            var changedColumns = [];
            var updateQueryString = [];
            var updateParameters = {
                'ID': row.$id,
                'Version': row.$version
            };
            for (var i = table.columns.length - 1; i >= 0; i--) {
                var column = table.columns[i];
                var columnName = column.name;
                var value = row[columnName];
                if (value !== void 0 && value !== row.$orig[columnName]) {
                    if (!checkColumnValue(column, value, fail)) {
                        return;
                    }
                    updateParameters[columnName] = value;
                    updateQueryString.push(columnName + ' = @' + columnName);
                    changedColumns.push(columnName);
                }
            }
            if (changedColumns.length === 0) {
                // if nothing has changed notify the listeners
                notifyAsync(row, row);
                succeed();
            }
            else {
                // persist the changes
                sql.nonQuery({
                    description: 'Zeile in Tabelle ' + name + ' ändern',
                    command: 'UPDATE dbo.' + name + '\n' +
                             'SET ' + updateQueryString.join(', ') + '\n' +
                             'WHERE ID = @ID AND Version = @Version' +
                             (filter ? (';\n' +
                             'IF @@ROWCOUNT > 0 AND NOT EXISTS (SELECT * FROM dbo.' + name + ' WHERE ID = @ID AND (' + filter + ')) RAISERROR(\'Der Eintrag entspricht nicht dem Tabellenfilter. [TN][' + name + ']\', 16, 1)'
                             ) : ''),
                    parameters: updateParameters,
                    allowReview: true,
                    allowError: true,
                    cancelOn: disposePromise
                }).then(
                    function (recordsAffected) {
                        if (recordsAffected !== 0) {
                            // update the original columns
                            for (var i = changedColumns.length - 1; i >= 0; i--) {
                                var columnName = changedColumns[i];
                                row.$orig[columnName] = row[columnName];
                            }

                            // notify the listeners if the current row is still the same
                            if (row.$id in rowIndex && rowIndex[row.$id] === row) {
                                notifyAsync(row, row);
                            }

                            // finish
                            succeed();
                        }
                        else {
                            fail({
                                statement: 0,
                                message: 'Die Zeile wurde geändert oder bereits gelöscht.',
                                table: name,
                                column: null
                            });
                        }
                    },
                    fail
                );
            }
        };

        var deleteRow = function (row, succeed, fail) {
            if (row.$id < 0) {
                // remove the unpersisted row
                table.rows.splice(indexOfRow(row), 1);
                delete rowIndex[row.$id];
                notifyAsync(row, null);
                succeed();
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
                    allowError: true,
                    cancelOn: disposePromise
                }).then(
                    function (recordsAffected) {
                        // delete the row if successful (and not done by notify), otherwise reject the promise
                        if (recordsAffected !== 0) {
                            if (row.$id in rowIndex) {
                                var currentRow = rowIndex[row.$id]; // NOTE: the row might have changed, so get the current one
                                table.rows.splice(indexOfRow(currentRow), 1);
                                delete rowIndex[row.$id];
                                notifyAsync(currentRow, null);
                            }

                            // finish
                            succeed();
                        }
                        else {
                            fail({
                                statement: 0,
                                message: 'Die Zeile wurde geändert oder bereits gelöscht.',
                                table: name,
                                column: null
                            });
                        }
                    },
                    fail
                );
            }
        };

        // set the public functions
        table.dispose = function () {
            // dispose the object
            if (!disposed) {
                disposeDeferred.resolve('Tabelle wird nicht mehr verwendet.');
                if (notificationPromise) {
                    notification.cancel(notificationPromise);
                    notificationPromise = null;
                }
                rowIndex = void 0;
                delete table.rows;
                disposed = true;
            }
        };
        table.name = name;
        table.filter = filter;
        table.columns = [];
        table.rows = [];
        table.ready = throwIfDisposed(function (fn) {
            ArgumentException.check(fn, 'fn', Function, true);

            // set the callback if given and return the promise
            if (fn) {
                readyEvent.promise.then(fn);
            }
            return readyEvent.promise;
        });
        table.addRowChangeListener = throwIfDisposed(function (fn) {
            ArgumentException.check(fn, 'fn', Function);

            // add the listener
            for (var i = changeListeners.length - 1; i >= 0; i--) {
                if (changeListeners[i] === fn) {
                    return false;
                }
            }
            changeListeners.push(fn);
            return true;
        });
        table.removeRowChangeListener = throwIfDisposed(function (fn) {
            ArgumentException.check(fn, 'fn', Function);

            // remove the listener
            for (var i = changeListeners.length - 1; i >= 0; i--) {
                if (changeListeners[i] === fn) {
                    changeListeners.splice(i, 1);
                    return true;
                }
            }
            return false;
        });
        table.getRowById = function (id) {
            // inline check for faster execution speed
            if (disposed) {
                throw new ObjectDisposedException('Tabelle ' + name);
            }
            // return the row at the index
            return rowIndex[id];
        };
        table.newRow = throwIfDisposed(throwIfNoColumns(function (row) {
            ArgumentException.check(row, 'row', Object, true);

            // create and add a row
            if (!row) {
                row = {};
            }
            for (var i = table.columns.length - 1; i >= 0; i--) {
                var column = table.columns[i];
                var columnName = column.name;
                if (row[columnName] === void 0 && !column.hasDefault && !column.required) {
                    row[columnName] = null;
                }
            }
            row.$id = nextNewRowId--;
            row.$version = '0x0000000000000000';
            row.$orig = {};
            table.rows.unshift(row);
            rowIndex[row.$id] = row;
            notifyAsync(null, row);
            return row;
        }));
        table.saveRow = throwIfDisposed(throwIfNoColumns(function (row) {
            // insert or update a row
            return rowAction(row, row.$id < 0 ? insertRow : updateRow, true);
        }));
        table.deleteRow = throwIfDisposed(throwIfNoColumns(function (row, setError) {
            ArgumentException.check(setError, 'setError', Boolean, true);

            // delete a row and only store the error if requested
            return rowAction(row, deleteRow, setError);
        }));

        // initialize the table when ready
        notification.ready(function () {
            // ensure we're not disposed
            if (disposed) {
                return;
            }

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
                         '  CASE WHEN d.type = \'D\' THEN 1 ELSE 0 END AS hasDefault,\n' +
                         '  (SELECT value FROM fn_listextendedproperty(\'width\', \'schema\', @Schema, \'table\', @Table, \'column\', c.name)) AS width,\n' +
                         '  CASE WHEN HAS_PERMS_BY_NAME(@Schema + N\'.\' + @Table,\'OBJECT\',\'UPDATE\',c.name,\'COLUMN\') = 1 THEN 0 ELSE 1 END AS readOnly,\n' +
                         '  OBJECT_NAME(f.referenced_object_id) AS referencedTable\n' +
                         'FROM\n' +
                         '  sys.columns AS c\n' +
                         '  JOIN\n' +
                         '  sys.types AS t ON c.user_type_id = t.user_type_id\n' +
                         '  LEFT OUTER JOIN\n' +
                         '  sys.foreign_key_columns AS f ON f.parent_object_id = c.object_id AND f.parent_column_id = c.column_id\n' +
                         '  LEFT OUTER JOIN\n' +
                         '  sys.default_constraints AS d ON d.parent_object_id = c.object_id AND d.parent_column_id = c.column_id\n' +
                         'WHERE\n' +
                         '  c.object_id = OBJECT_ID(@Schema + N\'.\' + @Table) AND\n' +
                         '  HAS_PERMS_BY_NAME(@Schema + N\'.\' + @Table,\'OBJECT\',\'SELECT\',c.name,\'COLUMN\') = 1 AND\n' +
                         '  c.is_computed = 0\n' +
                         'ORDER BY c.column_id',
                parameters: { 'Schema': 'dbo', 'Table': name },
                cancelOn: disposePromise
            }).then(function (data) {

                // check and store the columns
                if (data.length === 0) {
                    throw new UnauthorizedAccessException('Keine sichtbaren Spalten in Tabelle "' + name + '".');
                }
                if (data[0].name !== 'ID') {
                    throw new InvalidDataException('Die erste sichtbare Spalte in Tabelle "' + name + '" ist nicht "ID".');
                }
                if (data[data.length - 1].name !== 'Version') {
                    throw new InvalidDataException('Die letzte sichtbare Spalte in Tabelle "' + name + '" ist nicht "Version".');
                }
                var queryCommand = 'SELECT ';
                for (var i = 1; i < data.length - 1; i++) {
                    var column = data[i];
                    table.columns.push(column);
                    queryCommand += column.name + ', ';
                }

                // create the base command
                queryCommand += 'ID AS [$id], Version AS [$version]\nFROM dbo.' + name;
                if (filter) {
                    queryCommand += '\nWHERE (' + filter + ')';
                }

                // register a notification for database events
                notificationPromise = notification(function (events) {
                    if (name in events) {
                        // queue events for later if not ready or handle them now
                        if (eventsBeforeReady !== null) {
                            var newEventsBeforeReady = events[name];
                            for (var id in newEventsBeforeReady) {
                                var newVersion = newEventsBeforeReady[id];
                                if (newVersion !== null && id in eventsBeforeReady) {
                                    var version = eventsBeforeReady[id];
                                    if (version === null || newVersion <= version) {
                                        continue;
                                    }
                                }
                                eventsBeforeReady[id] = newVersion;
                            }
                        }
                        else {
                            handleNotifications(queryCommand, events[name]);
                        }
                    }
                });

                // retrieve the rows
                sql.query({
                    description: (filter ? 'Gefilterte' : 'Alle') + ' Zeilen von Tabelle ' + name + ' abfragen',
                    command: queryCommand,
                    cancelOn: disposePromise
                }).then(function (data) {
                    // add the rows and handle all queued events
                    indexAndCheckData(data, null);
                    handleNotifications(queryCommand, eventsBeforeReady);
                    eventsBeforeReady = null;
                    readyEvent.resolve(table);
                });
            });
        });
    };
})

// define dataset functions
.service('dataSet', function ($q, ReferenceLabels, sql, Table) {
    var Div = document.createElement('div').constructor;
    var dataSet;

    // map structures
    var tables = {};
    var references = {};
    var labels = {};

    // define the view object
    var View = function View(tableName, parentElement, settings) {
        var view = this;

        // fast and umlaut-aware string comparer (if possible)
        var compareString = (function () {
            if (window.Intl && window.Intl.Collator) {
                var collator = new Intl.Collator('de', { numeric: true });
                return collator.compare;
            }
            else {
                return function (a, b) {
                    a = a.toLowerCase();
                    b = b.toLowerCase();
                    return a < b ? -1 : b < a ? 1 : 0;
                };
            }
        })();
        var fastDateRenderer = function (instance, TD, row, col, prop, value, cellProperties) {
            if (value === null) {
                value = '';
            }
            else if (value instanceof Date) {
                // format the date to string
                var day = value.getDate();
                var month = value.getMonth() + 1;
                var year = value.getFullYear();
                value = '';
                if (day < 10) {
                    value += '0';
                }
                value += day + '.';
                if (month < 10) {
                    value += '0';
                }
                value += month + '.' + year;
            }
            if (cellProperties.readOnly) {
                Handsontable.renderers.TextRenderer(instance, TD, row, col, prop, value, cellProperties);
            }
            else {
                Handsontable.renderers.AutocompleteRenderer(instance, TD, row, col, prop, value, cellProperties);
            }
        };

        // label column type methods
        var labelsRenderer = function (instance, TD, row, col, prop, value, cellProperties) {
            // find the label
            if (value === null) {
                value = '';
            }
            else {
                var label = labels[cellProperties.referencedTable];
                if (label != void 0) {
                    value = label[value];
                    if (value == void 0) {
                        value = '(' + cellProperties.referencedTable + ' #' + value + ' fehlt)';
                    }
                }
                else {
                    value = '(' + cellProperties.referencedTable + ' #' + value + ' nicht geladen)';
                }
            }
            if (cellProperties.readOnly) {
                Handsontable.renderers.TextRenderer(instance, TD, row, col, prop, value, cellProperties);
            }
            else {
                Handsontable.renderers.AutocompleteRenderer(instance, TD, row, col, prop, value, cellProperties);
            }
        };
        var labelsComparer = function (sortOrder) {
            // return the numeric comparer if there are no labels
            if (!(this.referencedTable in labels)) {
                return Handsontable.NumericCell.comparer(sortOrder);
            }

            // generate the flags and compare function
            var label = labels[this.referencedTable];
            var aNotB = sortOrder ? 1 : -1;
            var bNotA = sortOrder ? -1 : 1;
            return function (a, b) {
                if (a[1] !== null && b[1] !== null) {
                    var hasA = a[1] in label;
                    var hasB = b[1] in label;
                    if (hasA && hasB) {
                        return sortOrder ? compareString(label[a[1]], label[b[1]]) : compareString(label[b[1]], label[a[1]]);
                    }
                    else if (hasA) {
                        return aNotB;
                    }
                    else if (hasB) {
                        return bNotA;
                    }
                    else {
                        return sortOrder ? a[1] - b[1] : b[1] - a[1];
                    }
                }
                else if (a[1] !== null) {
                    return aNotB;
                }
                else if (b[1] !== null) {
                    return bNotA;
                }
                else {
                    return 0;
                }
            };
        };
        var labelsFormatCopyable = function (value) {
            if (this.referencedTable in labels) {
                var label = labels[this.referencedTable];
                if (value in label) {
                    return '"' + label[value].replace(/"/g, '""') + '"';
                }
            }
            return value.toLocaleString();
        };

        // editor for label columns
        var LabelsEditor = Handsontable.editors.SelectEditor.prototype.extend();
        LabelsEditor.prototype.prepare = function () {
            Handsontable.editors.BaseEditor.prototype.prepare.apply(this, arguments);
            // get and sort the options
            var options = this.cellProperties.referencedTable in labels ? labels[this.cellProperties.referencedTable] : {};
            var sortOptions = [];
            for (var value in options) {
                sortOptions.push([value, options[value]]);
            }
            sortOptions.sort(function (a, b) { return -compareString(a[1], b[1]); });

            // clear all previous options
            while (this.select.firstChild) {
                this.select.removeChild(this.select.firstChild);
            }

            // add the null option together with all the other options
            sortOptions.push(['', '']);
            for (var i = sortOptions.length - 1; i >= 0; i--) {
                var optionElement = document.createElement('OPTION');
                optionElement.value = sortOptions[i][0];
                optionElement.text = sortOptions[i][1];
                this.select.appendChild(optionElement);
            }
        };
        LabelsEditor.prototype.getValue = function () {
            // return null or a number
            return this.select.value === '' ? null : Number(this.select.value);
        };

        // state variables
        var instance = null;
        var disposed = false;
        var hookedTable = null;
        var dataChanged = false;
        var queuedRender = false;
        var selection = null;

        // helpers
        var throwIfDisposed = function (fn) {
            return function () {
                if (disposed) {
                    throw new ObjectDisposedException('Ansicht ' + tableName);
                }
                return fn.apply(this, arguments);
            };
        };
        var isVisible = function (startRow, startCol, endRow, endCol) {
            // check whether the selection is (almost) in the viewport
            var viewport = instance.view.wt.getViewport();
            return startRow <= viewport[2] && startCol <= viewport[3] && endRow >= viewport[0] && endCol >= viewport[1];
        };
        var onScroll = function () {
            // update whether the selection is visisble
            if (selection) {
                selection.visible = isVisible(selection.startRow, selection.startCol, selection.endRow, selection.endCol);
            }
        };
        var onSelect = function (startRow, startCol, endRow, endCol) {
            // set the selection and its source rows
            selection = {
                startRow: startRow,
                startCol: startCol,
                endRow: endRow,
                endCol: endCol,
                visible: true
            };
            startRow = instance.runHooks('modifyRow', startRow);
            selection.startSourceRow = instance.getSourceDataAtRow(startRow);
            endRow = instance.runHooks('modifyRow', endRow);
            selection.endSourceRow = instance.getSourceDataAtRow(endRow);
        };
        var onDeselect = function () {
            // clear the selection
            selection = null;
        };
        var getRowById = function (rowId) {
            // return the visible index of the row with the given id or null
            for (var visibleIndex = instance.countRows() - 1; visibleIndex >= 0; visibleIndex--) {
                var sourceIndex = instance.runHooks('modifyRow', visibleIndex);
                if (rowId === instance.getSourceDataAtRow(sourceIndex).$id) {
                    return visibleIndex;
                }
            }
            return null;
        };
        var reselect = function () {
            // simply deselect if there is no selection
            if (!selection) {
                instance.selection.deselect();
                return;
            }

            // find the old selected rows
            selection.startRow = getRowById(selection.startSourceRow.$id);
            selection.endRow = getRowById(selection.endSourceRow.$id);

            // update the selection
            if (selection.startRow === null && selection.endRow === null) {
                selection = null;
                instance.selection.deselect();
            }
            else {
                // make sure both indices are set and determine if we should scroll to the cell
                if (selection.startRow === null) {
                    selection.startRow = selection.endRow;
                    selection.startSourceRow = selection.endSourceRow;
                }
                if (selection.endRow === null) {
                    selection.endRow = selection.startRow;
                    selection.endSourceRow = selection.startSourceRow;
                }
                var scrollToCell = selection.visible && !isVisible(selection.startRow, selection.startCol, selection.endRow, selection.endCol);

                // update the selection while keeping the editor open
                instance.selectCell(selection.startRow, selection.startCol, selection.endRow, selection.endCol, scrollToCell, false, true);
                if (scrollToCell) {
                    instance.view.wt.scrollViewport({ row: selection.startRow, col: selection.startCol });
                }
            }
        };
        var render = function () {
            // ensure we are not disposed
            if (disposed) {
                return;
            }

            // clear the render flag and check if the instance still exists and is visible
            queuedRender = false;
            if (instance && parentElement.offsetParent) {
                // determine what is necessary
                if (dataChanged) {
                    // clear the flag and get the current editor settings
                    dataChanged = false;
                    var editor = instance.getActiveEditor();
                    var sourceRow = editor ? editor.cellProperties.sourceRow : null;

                    // resort and render (this alters the editor's cell properties)
                    instance.getPlugin('columnSorting').sort();
                    instance.render();

                    // discard or move the editor
                    if (editor) {
                        var row = getRowById(sourceRow.$id);
                        if (row === null) {
                            if (editor.state === Handsontable.EditorState.EDITING) {
                                editor.cancelChanges();
                            }
                        }
                        else {
                            editor.row = row;
                            editor.cellProperties = instance.getCellMeta(editor.row, editor.col);
                            if (editor.refreshDimensions) {
                                editor.refreshDimensions();
                            }
                        }
                    }

                    // select the old selection
                    reselect();
                }
                else {
                    // redraw the instance
                    instance.render();
                }
            }
        };
        var createInstance = function (table) {
            // generate a column index
            var columnIndex = {};
            for (var i = table.columns.length - 1; i >= 0; i--) {
                var indexedColumn = table.columns[i];
                columnIndex[indexedColumn.name] = indexedColumn;
            }

            // create the columns array if necessary
            if (settings.columns === void 0) {
                settings.columns = [];
                for (var j = 0; j < table.columns.length; j++) {
                    if (table.columns[j].type !== 'varbinary') {
                        settings.columns.push({
                            data: table.columns[j].name,
                            title: table.columns[j].name
                        });
                    }
                }
            }


            // create the cells function
            var actualCells = settings.cells;
            settings.cells = function (row, col, prop) {
                // get and store the source row
                var instance = this.instance;
                var sourceRow = instance.getSourceDataAtRow(row);
                this.sourceRow = sourceRow;
                if (sourceRow) {
                    // set the read only state and call the actual cells function
                    this.readOnly = sourceRow.$action || prop in columnIndex && columnIndex[prop].readOnly;
                    if (actualCells !== void 0) {
                        actualCells(instance, sourceRow, row, col, prop, this);
                    }
                }
                else {
                    // this can happen if there are no rows
                    this.readOnly = true;
                }
            };

            // disable observing changes, enable sorting, resizing and limit row rendering
            settings.observeChanges = false;
            settings.observeDOMVisibility = false;
            settings.columnSorting = true;
            settings.autoColumnSize = false;
            settings.autoRowSize = false;
            settings.manualColumnResize = true;
            settings.manualRowResize = true;
            settings.viewportColumnRenderingOffset = 2;
            settings.viewportRowRenderingOffset = 10;

            // adjust all columns
            for (var k = settings.columns.length - 1; k >= 0; k--) {
                var column = settings.columns[k];

                // always show the sort indicator
                column.sortIndicator = true;

                // check if the hot column matches a table column
                if (column.data in columnIndex) {
                    var tableColumn = columnIndex[column.data];
                    if (tableColumn.name === column.data) {
                        // set the common attributes
                        if (tableColumn.readOnly) {
                            column.readOnly = true;
                        }
                        var width = Number(tableColumn.width);
                        column.width = isNaN(width) || width <= 0 ? 100 : width;
                        column.language = 'de';

                        // set the type specific attributes
                        switch (tableColumn.type) {
                            case 'int':
                                column.type = 'numeric';
                                column.format = '0';
                                if (tableColumn.referencedTable) {
                                    column.editor = LabelsEditor;
                                    column.renderer = labelsRenderer;
                                    column.comparer = labelsComparer;
                                    column.className = void 0;
                                    column.referencedTable = tableColumn.referencedTable;
                                    column.formatCopyable = labelsFormatCopyable;
                                    if (tableColumn.referencedTable in references) {
                                        references[tableColumn.referencedTable].push(view);
                                    }
                                    else {
                                        references[tableColumn.referencedTable] = [view];
                                    }
                                }
                                break;
                            case 'char':
                            case 'varchar':
                            case 'nchar':
                            case 'nvarchar':
                                column.type = 'text';
                                column.trimWhitespace = true;
                                break;
                            case 'datetime':
                                column.type = 'date';
                                column.dateFormat = 'DD.MM.YYYY';
                                column.dateFactory = Date.create;
                                column.renderer = fastDateRenderer;
                                column.datePickerConfig = {
                                    firstDay: 1,
                                    showWeekNumber: true,
                                    i18n: {
                                        previousMonth: 'Vorheriger Monat',
                                        nextMonth: 'Nächster Monat',
                                        months: ['Jänner', 'Feber', 'März', 'April', 'Mai', 'Juni', 'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember'],
                                        weekdays: ['Sonntag', 'Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag', 'Samstag'],
                                        weekdaysShort: ['So', 'Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa']
                                    }
                                };
                                break;
                            case 'decimal':
                                column.type = 'numeric';
                                column.format = '0';
                                if (tableColumn.scale > 0) {
                                    column.format += '.';
                                    for (var n = tableColumn.scale; n > 0; n--) {
                                        column.format += '0';
                                    }
                                }
                                break;
                            case 'money':
                                column.type = 'numeric';
                                column.format = '$ 0,0.00';
                                break;
                            case 'bit':
                                column.type = 'checkbox';
                                break;
                            default:
                                throw new InvalidOperationException('Der Typ "' + tableColumn.type + '" von Spalte "' + tableColumn.name + '" in Tabelle "' + table.name + '" wird nicht unterstützt.');
                        }
                    }
                }
            }

            // finalize the settings and create the instance
            settings.data = table.rows;
            var hot = new Handsontable(parentElement, settings);

            // remove the ability to alter rows or columns
            hot.alter = function () { };
            return hot;
        };

        // event listener
        view.on = throwIfDisposed(function (type, listener) {
            ArgumentException.check(type, 'type', String);
            ArgumentException.check(listener, 'listener', Function);

            // wrap the listener to be called with instance as this
            parentElement.addEventListener(type, function (event) {
                listener.call(instance, event);
            });
        });

        // methods for hooking and unhooking
        view.isTableName = throwIfDisposed(function (name) {
            return name === tableName;
        });
        view.hook = throwIfDisposed(function (table) {
            ArgumentException.check(table, 'table', Table);

            // make sure the view is unhooked
            if (hookedTable) {
                throw new InvalidOperationException('Die Ansicht für Tabelle "' + tableName + '" ist bereits gebunden.');
            }

            // set the table and do the rest asynchronously
            hookedTable = table;
            setTimeout(function () {
                // make sure we are not disposed and the table is still hooked
                if (disposed || hookedTable !== table) {
                    return;
                }

                // either load the date or create the instance
                if (instance) {
                    instance.loadData(table.rows);
                }
                else {
                    instance = createInstance(table);
                    instance.addHook('afterSelection', onSelect);
                    instance.addHook('afterDeselect', onDeselect);
                    instance.addHook('afterScrollHorizontally', onScroll);
                    instance.addHook('afterScrollVertically', onScroll);
                    var currentSelection = instance.getSelected();
                    if (currentSelection === void 0) {
                        onDeselect();
                    }
                    else {
                        onSelect(currentSelection[0], currentSelection[1], currentSelection[2], currentSelection[3]);
                    }
                }
            }, 0);
        });
        view.unhook = throwIfDisposed(function (table) {
            ArgumentException.check(table, 'table', Table);

            if (hookedTable !== table) {
                throw new InvalidOperationException('Die Ansicht für Tabelle "' + tableName + '" ist an eine andere Tabelleninstanz gebunden.');
            }
            hookedTable = null;
            instance.loadData([]);
        });

        // method for disposing the view
        view.dispose = throwIfDisposed(function () {
            disposed = true;

            // unhook and destroy the instance
            hookedTable = null;
            if (instance) {
                instance.removeHook('afterScrollVertically', onScroll);
                instance.removeHook('afterScrollHorizontally', onScroll);
                instance.removeHook('afterDeselect', onDeselect);
                instance.removeHook('afterSelection', onSelect);
                instance.destroy();
                instance = null;
            }

            // remove any references
            for (var name in references) {
                var views = references[name];
                for (var i = views.length - 1; i >= 0; i--) {
                    if (views[i] === view) {
                        views.splice(i, 1);
                    }
                }
            }
        });

        // method that schedules a render for later
        view.invalidate = function (all) {
            if (instance) {
                if (all) {
                    dataChanged = true;
                }
                if (!queuedRender) {
                    queuedRender = true;
                    setTimeout(render, 0);
                }
            }
        };

        // add the view to the table references
        if (tableName in references) {
            references[tableName].push(view);
        }
        else {
            references[tableName] = [view];
        }
    };

    // helper functions to render foreign keys and base tables
    var rowChange = function (table, oldRow, newRow) {
        // update the labels
        if (table.name in labels) {
            var label = labels[table.name];
            if (oldRow) {
                delete label[oldRow.$id];
            }
            if (newRow) {
                var value = ReferenceLabels[table.name](newRow);
                if (value == void 0 || value.constructor !== String) {
                    value = '';
                }
                label[newRow.$id] = value;
            }
        }

        // render all referencing hot tables
        var views = references[table.name];
        for (var i = views.length - 1; i >= 0; i--) {
            var view = views[i];
            view.invalidate(view.isTableName(table.name));
        }
    };
    var internalCreateTable = function (name, filter) {
        // make sure the view array exists
        if (!(name in references)) {
            references[name] = [];
        }

        // get the permissions if not in the cache
        if (!(name in dataSet.permissions)) {
            dataSet.permissions[name] = {};
            sql.query({
                description: 'Berechtigungen für Tabelle ' + name + ' abfragen',
                command: 'SELECT\n' +
                         '  HAS_PERMS_BY_NAME(@Table,\'OBJECT\',\'INSERT\') AS allowNew,\n' +
                         '  HAS_PERMS_BY_NAME(@Table,\'OBJECT\',\'UPDATE\') AS allowEdit,\n' +
                         '  HAS_PERMS_BY_NAME(@Table,\'OBJECT\',\'DELETE\') AS allowDelete',
                parameters: { 'Table': 'dbo.' + name }
            }).then(function (data) {
                // store the permissions and render all views of this table again
                dataSet.permissions[name] = data[0];
                var views = references[name];
                for (var i = views.length - 1; i >= 0; i--) {
                    var view = views[i];
                    if (view.isTableName(name)) {
                        view.invalidate();
                    }
                }
            });
        }

        // create and add the table
        var table = new Table(name, filter);
        tables[name] = table;

        // wait for the table to be ready
        table.ready(function () {
            // make sure the same table is still loaded
            if (name in tables && tables[name] === table) {
                // build all labels if there is a reference
                if (name in ReferenceLabels) {
                    var label = {};
                    var rows = table.rows;
                    for (var i = rows.length - 1; i >= 0; i--) {
                        var row = rows[i];
                        label[row.$id] = ReferenceLabels[name](row);
                    }
                    labels[name] = label;
                }

                // hook the listener and create all views or invalidate foreign views
                table.addRowChangeListener(rowChange);
                var views = references[name];
                for (var j = views.length - 1; j >= 0; j--) {
                    var view = views[j];
                    if (view.isTableName(name)) {
                        view.hook(table);
                    }
                    else {
                        view.invalidate();
                    }
                }
            }
        });

        // return the table
        return table;
    };
    var internalDestroyTable = function (table) {
        // delete the table from the list
        var name = table.name;
        delete tables[name];

        // try to unhooks the listener (only successful if ready event was triggered)
        if (table.removeRowChangeListener(rowChange)) {
            // if it was registered also delete the labels if a reference exists
            if (name in ReferenceLabels) {
                delete labels[name];
            }

            // clear the views and invalidate foreign views
            var views = references[name];
            for (var i = views.length - 1; i >= 0; i--) {
                var view = views[i];
                if (view.isTableName(name)) {
                    view.unhook(table);
                }
                else {
                    view.invalidate();
                }
            }
        }

        // dispose the table
        table.dispose();
    };

    // define the data set functions
    dataSet = {
        permissions: {},
        ready: function (fn) {
            ArgumentException.check(fn, 'fn', Function, true);

            // combine all table ready states
            var promises = [];
            for (var tableName in tables) {
                promises.push(tables[tableName].ready());
            }
            var promise = $q.all(promises);

            // enlist the callback and return the combined promise
            if (fn) {
                promise.then(fn);
            }
            return promise;
        },
        load: function (definitions) {
            ArgumentException.check(definitions, 'definitions', Array);
            var name;

            // store the old tables
            var oldTables = {};
            for (name in tables) {
                oldTables[name] = tables[name];
            }
            var newTables = {};

            // build the new maps
            for (var i = definitions.length - 1; i >= 0; i--) {
                var definition = definitions[i];
                name = definition.name;

                // ensure the table wasn't defined twice
                if (name in newTables) {
                    throw new InvalidOperationException('Es wurde versucht die Tabelle "' + name + '" mehrfach zu laden.');
                }

                // check if the table can be reused
                if (name in oldTables) {
                    if (oldTables[name].filter === definition.filter) {
                        // reuse the table
                        newTables[name] = oldTables[name];
                    }
                    else {
                        // unload the old table before loading it with a different filter
                        internalDestroyTable(oldTables[name]);
                        newTables[name] = internalCreateTable(name, definition.filter);
                    }
                    delete oldTables[name];
                }
                else {
                    newTables[name] = internalCreateTable(name, definition.filter);
                }
            }

            // remove old unused tables
            for (name in oldTables) {
                internalDestroyTable(oldTables[name]);
            }
        },
        getTable: function (name) {
            ArgumentException.check(name, 'name', String);

            // make sure the table is loaded before returning it
            if (!(name in tables)) {
                throw new InvalidOperationException('Die Tabelle "' + name + '" ist nicht geladen.');
            }
            return tables[name];
        },
        addTable: function (name, filter) {
            // ensure the tables isn't already loaded before creating it
            if (name in tables) {
                throw new InvalidOperationException('Die Tabelle "' + name + '" existiert bereits.');
            }
            return internalCreateTable(name, filter);
        },
        removeTable: function (table) {
            ArgumentException.check(table, 'table', Table);

            // ensure the table is loaded before destroying it
            if (!(table.name in tables) || tables[table.name] !== table) {
                throw new InvalidOperationException('Die Tabelle "' + table.name + '" wurde nicht geladen.');
            }
            internalDestroyTable(table);
        },
        actionIcon: '<i class="uk-icon-refresh uk-icon-spin"></i>',
        errorIcon: function (message) {
            ArgumentException.check(message, 'message', String);

            // escape the message and embed it as tooltip
            var entityMap = {
                '&': '&amp;',
                '<': '&lt;',
                '>': '&gt;',
                '"': '&quot;',
                "'": '&#39;',
                '/': '&#47;'
            };
            message = message.replace(/[&<>"'\/]/g, function (ch) { return entityMap[ch]; });
            return '<i data-uk-tooltip="data-uk-tooltip" title="' + message + '" class="uk-icon-exclamation-triangle"></i>';
        },
        primaryFilter: function (role, superRole) {
            ArgumentException.check(role, 'role', String);
            ArgumentException.check(superRole, 'superRole', String, true);

            // create a permission filter for the Einrichtung table
            var filter = 'IS_MEMBER(SUSER_SNAME(' + role + ')) = 1';
            if (superRole) {
                filter += ' OR IS_MEMBER(\'' + superRole + '\') = 1';
            }
            return filter;
        },
        secondaryFilter: function (role, superRole) {
            ArgumentException.check(role, 'role', String);
            ArgumentException.check(superRole, 'superRole', String, true);

            // create a permission filter for a table referencing Einrichtung
            return 'Einrichtung IN (SELECT ID FROM dbo.Einrichtung WHERE ' + dataSet.primaryFilter(role, superRole) + ')';
        },
        createView: function (tableName, parentElement, settings) {
            ArgumentException.check(tableName, 'tableName', String);
            ArgumentException.check(parentElement, 'parentElement', Div);
            ArgumentException.check(settings, 'settings', Object);

            // create the view and make sure it gets loaded if the table exists and is ready
            var view = new View(tableName, parentElement, settings);
            if (tableName in tables) {
                var table = tables[tableName];
                if (table.removeRowChangeListener(rowChange)) {
                    table.addRowChangeListener(rowChange);
                    view.hook(table);
                }
            }
            return view;
        },
        destroyView: function (view) {
            ArgumentException.check(view, 'view', View);

            // dispose the view
            view.dispose();
        }
    };

    // return the data set functions
    return dataSet;
})

// define the trainee attendance controller
.controller('AttendanceController', function ($scope, $element, $filter, Roles, dataSet) {
    var ctr = this;
    var hot = null;

    // helper functions
    var lastOrdinaryColumn = 2;
    var checkedDateProp = 'Überprüft';
    var getDateFromWeekDay = function (weekDay) {
        return Date.create(ctr.monday.getTime() + (((weekDay + 6) % 7) * (24 * 60 * 60 * 1000)));
    };
    var getMondayByWeekOffset = function (offset) {
        return Date.create(ctr.monday.getTime() + (offset * 7 * 24 * 60 * 60 * 1000));
    };
    var getSundayByWeekOffset = function (offset) {
        return Date.create(ctr.monday.getTime() + (((offset * 7) + 6) * 24 * 60 * 60 * 1000));
    };
    var formatTime = function (time) {
        // formats a date object into a 00:00 time string
        var result = '';
        var hours = time.getHours();
        var minutes = time.getMinutes();
        if (hours < 10) {
            result += '0';
        }
        result += hours;
        result += ':';
        if (minutes < 10) {
            result += '0';
        }
        result += minutes;
        return result;
    };

    // attendance variables and functions
    var attendance = {};
    var zeitspanne = null;
    var anwesenheit = null;
    var formatAnwesenheit = function (weekDays, weekDay) {
        // format the day to html
        var result = '<span class="bitmask-';
        if (weekDay in weekDays) {
            var row = weekDays[weekDay];
            result += (row.Vormittags ? '1' : '0') + (row.Nachmittags ? '1' : '0') + (row.Nachts ? '1' : '0') + '">';
            result += formatTime(row.Zusatz);
            result += '</span>';
            if (row.$action) {
                result += dataSet.actionIcon;
            }
            else if (row.$error) {
                result += dataSet.errorIcon(row.$error.message);
            }
        }
        else {
            result += '000 missing">00:00</span>';
        }

        // store the result and render
        weekDays.formatted[weekDay] = result;
        hot.invalidate();
    };
    var getWeekDays = function (zeitspanneId) {
        // create the weekdays if they don't exist
        if (!(zeitspanneId in attendance)) {
            var weekDays = { formatted: {} };
            for (var weekDay = 0; weekDay < 7; weekDay++) {
                formatAnwesenheit(weekDays, weekDay);
            }
            attendance[zeitspanneId] = weekDays;
        }
        return attendance[zeitspanneId];
    };
    var changeAnwesenheit = function (zeitspanneId, weekDay, fn) {
        // get or create the row object
        var zeroTime = Date.create(1900, 0, 1);
        var weekDays = getWeekDays(zeitspanneId);
        var row;
        if (weekDay in weekDays) {
            row = weekDays[weekDay];
            if (row.$action) {
                UIkit.modal.alert('Die Zeile wird bereits geändert.');
                return;
            }
        }
        else {
            row = {
                Zeitspanne: zeitspanneId,
                Datum: getDateFromWeekDay(weekDay),
                Vormittags: false,
                Nachmittags: false,
                Nachts: false,
                Zusatz: zeroTime
            };
            anwesenheit.newRow(row);
        }

        // change the row
        fn(row);

        // define a callback that updates the row
        var reformatAnwesenheit = function () {
            // make sure the row is sill the same
            if (weekDay in weekDays && weekDays[weekDay] === row) {
                formatAnwesenheit(weekDays, weekDay);
            }
        };

        // save or delete the row if its empty
        var promise = !row.Vormittags && !row.Nachmittags && !row.Nachts && row.Zusatz.getTime() === zeroTime.getTime() ?
            anwesenheit.deleteRow(row, true) :
            anwesenheit.saveRow(row);
        promise.then(null, reformatAnwesenheit);

        // update the row to indicate the action
        reformatAnwesenheit();
    };
    var handleZeitspanneRowChange = function (table, oldRow, newRow) {
        // remove the html from the old row
        if (oldRow) {
            delete oldRow.$Anwesenheit;
        }

        // add the html to the new row
        if (newRow) {
            newRow.$Anwesenheit = getWeekDays(newRow.$id).formatted;
        }

        // rerender
        hot.invalidate();
    };
    var handleAnwesenheitRowChange = function (table, oldRow, newRow) {
        // define a helper function
        var doUpdate = function (row, fn) {
            if (row) {
                var weekDays = getWeekDays(row.Zeitspanne);
                var weekDay = row.Datum.getDay();
                if (fn(row, weekDays, weekDay)) {
                    formatAnwesenheit(weekDays, weekDay);
                }
            }
        };

        // remove the day if the old row exists and is not older
        doUpdate(oldRow, function (row, weekDays, weekDay) {
            if (!(weekDay in weekDays) || weekDays[weekDay].$version > row.$version) {
                return false;
            }
            delete weekDays[weekDay];
            return true;
        });

        // add the day if no row exists or the row is newer
        doUpdate(newRow, function (row, weekDays, weekDay) {
            if (weekDay in weekDays && weekDays[weekDay].$version > row.$version) {
                return false;
            }
            weekDays[weekDay] = row;
            return true;
        });
    };

    // holiday variables and functions
    var holidays = {};
    var feiertag = null;
    var handleFeiertagRowChange = function (table, oldRow, newRow) {
        var render = false;

        // remove old holidays and add new holidays
        if (oldRow) {
            var oldDay = oldRow.Datum.getDay();
            if (oldDay in holidays && holidays[oldDay].$version <= oldRow.$version) {
                delete holidays[oldDay];
                render = true;
            }
        }
        if (newRow) {
            var newDay = newRow.Datum.getDay();
            if (!(newDay in holidays) || newDay in holidays && holidays[newDay].$version <= newRow.$version) {
                holidays[newDay] = newRow;
                render = true;
            }
        }

        // redraw the header if necessary
        if (render) {
            hot.invalidate();
        }
    };

    // handson table variable and build function
    var hotHeaders = function (col) {
        switch (col) {
            case 0: return 'Einrichtung';
            case 1: return 'Teilnehmer';
            case 2: return 'Kontrolliert bis';
            default:
                // return either the holiday name or the formatted day string
                var weekDay = (col - lastOrdinaryColumn) % 7;
                if (weekDay in holidays) {
                    return holidays[weekDay].Name;
                }
                return $filter('date')(getDateFromWeekDay(weekDay), 'EEE, d.M.');
        }
    };
    var hotBeforeChange = function (changes) {
        // create a function that sets all attributes
        var createSetter = function (vormittags, nachmittags, nachts, zusatz) {
            return function (row) {
                row.Vormittags = vormittags;
                row.Nachmittags = nachmittags;
                row.Nachts = nachts;
                row.Zusatz = zusatz;
            };
        };

        // go over all changes
        var instance = this;
        var revertCheckedDateWithError = function (row) {
            return function (error) {
                row[checkedDateProp] = row.$orig[checkedDateProp];
                zeitspanne.saveRow(row);
                UIkit.modal.alert(error);
            };
        };
        $scope.$apply(function () {
            for (var i = changes.length - 1; i >= 0; i--) {
                var change = changes[i];

                // check if a weekday was edited
                var index = instance.runHooks('modifyRow', change[0]);
                var propMatch = change[1].match(/^\$Anwesenheit\.([0-6])$/);
                if (propMatch) {
                    // ensure the value is string and make sure the weekday is editable
                    var weekDay = Number(propMatch[1]);
                    if (change[3] != void 0 && change[3].constructor === String) {
                        // make sure the format is value
                        var valueMatch = change[3].match(/^<span class="bitmask-([01])([01])([01])( missing)?">(\d\d):(\d\d)<\/span>/);
                        if (valueMatch && Number(valueMatch[5]) < 24 && Number(valueMatch[6]) < 60) {
                            // change the attributes
                            var zeitspanneId = instance.getSourceDataAtRow(index).$id;
                            changeAnwesenheit(zeitspanneId, weekDay, createSetter(Number(valueMatch[1]) === 1, Number(valueMatch[2]) === 1, Number(valueMatch[3]) === 1, Date.create(1900, 0, 1, Number(valueMatch[5]), Number(valueMatch[6]))));
                        }
                    }
                }
                else if (change[1] === checkedDateProp) {
                    // ensure the value is null or a date
                    if (change[3] == void 0 || change[3].constructor === Date) {
                        var row = instance.getSourceDataAtRow(index);
                        row[checkedDateProp] = change[3];
                        zeitspanne.saveRow(row).then(null, revertCheckedDateWithError(row));
                        hot.invalidate();
                    }
                }
            }
        });
        return false;
    };
    var hotClick = function (event) {
        // check the cell
        if (!event.target || event.target.tagName !== 'SPAN' || !event.target.parentNode || event.target.parentNode.tagName !== 'TD') {
            return;
        }
        var coords = this.getCoords(event.target.parentNode);
        if (coords.row < 0 || coords.col <= lastOrdinaryColumn || this.getCellMeta(coords.row, coords.col).readOnly) {
            return;
        }

        // get the common variable and calculate the position
        var index = this.runHooks('modifyRow', coords.row);
        var zeitspanneId = this.getSourceDataAtRow(index).$id;
        var weekDay = (coords.col - lastOrdinaryColumn) % 7;
        var pos = event.clientX;
        for (var parent = event.target; parent; parent = parent.offsetParent) {
            pos -= parent.offsetLeft;
        }

        // change the Anwesenheit depending on the click position
        if (pos > 33) {
            // set the new time
            var oldTime = zeitspanneId in attendance && weekDay in attendance[zeitspanneId] ?
                formatTime(attendance[zeitspanneId][weekDay].Zusatz) :
                '00:00';
            UIkit.modal.prompt('Zusatz:', oldTime, function (newTime) {
                var match = newTime.match(/^(\d\d):(\d\d)$/);
                if (match && Number(match[1]) < 24 && Number(match[2]) < 60) {
                    $scope.$apply(function () {
                        changeAnwesenheit(zeitspanneId, weekDay, function (row) {
                            row.Zusatz = Date.create(1900, 0, 1, Number(match[1]), Number(match[2]));
                        });
                    });
                }
                else {
                    UIkit.modal.alert('"' + newTime + '" ist keine gültige Uhrzeit.');
                }
            });
        }
        else {
            // toggle the states
            $scope.$apply(function () {
                changeAnwesenheit(zeitspanneId, weekDay, function (row) {
                    if (pos < 19) {
                        if (row.Vormittags && row.Nachmittags) {
                            row.Vormittags = false;
                        }
                        else if (row.Vormittags) {
                            row.Nachmittags = true;
                        }
                        else if (row.Nachmittags) {
                            row.Nachmittags = false;
                        }
                        else {
                            row.Vormittags = true;
                        }
                    }
                    else {
                        row.Nachts = !row.Nachts;
                    }
                });
            });
        }
    };
    var hotFormatCopyable = function (value) {
        // parse the single html value and return each component as a value on its on
        var match = value.match(/^<span class="bitmask-([01])([01])([01])( missing)?">(\d\d:\d\d)<\/span>/);
        if (!match || match[4] && this.readOnly) {
            return '\t\t\t';
        }
        return match[1] + '\t' + match[2] + '\t' + match[3] + '\t' + match[5];
    };
    var hotColumns = (function () {
        // create the two main columns and add the day columns
        var columns = [
            { data: 'Einrichtung', readOnly: true },
            { data: 'Teilnehmer', readOnly: true },
            { data: checkedDateProp }
        ];
        for (var i = 1; i <= 7; i++) {
            columns.push({
                data: '$Anwesenheit.' + (i % 7),
                width: 100,
                renderer: 'html',
                formatCopyable: hotFormatCopyable,
                editor: false
            });
        }
        return columns;
    })();
    var hotCells = function (instance, sourceRow, row, col, prop, cellProperties) {
        if (col > lastOrdinaryColumn) {
            // mark days outside the Zeitspanne as readonly
            var weekDay = (col - lastOrdinaryColumn) % 7;
            var date = getDateFromWeekDay(weekDay).getTime();
            cellProperties.readOnly = date < sourceRow.Eintritt.getTime() || sourceRow.Austritt && date > sourceRow.Austritt.getTime();

            // set the class name depending on the day
            cellProperties.className = 'attendance';
            if (weekDay in holidays) {
                cellProperties.className += ' holiday';
            }
            else if (col === lastOrdinaryColumn + 6) {
                cellProperties.className += ' saturday';
            }
            else if (col === lastOrdinaryColumn + 7) {
                cellProperties.className += ' sunday';
            }
        }
    };

    // cleanup helper function
    var cleanup = function () {
        ctr.weeks = [];
        attendance = {};
        holidays = {};
        if (zeitspanne) {
            zeitspanne.removeRowChangeListener(handleZeitspanneRowChange);
            dataSet.removeTable(zeitspanne);
            zeitspanne = null;
        }
        if (anwesenheit) {
            anwesenheit.removeRowChangeListener(handleAnwesenheitRowChange);
            dataSet.removeTable(anwesenheit);
            anwesenheit = null;
        }
        if (feiertag) {
            feiertag.removeRowChangeListener(handleFeiertagRowChange);
            dataSet.removeTable(feiertag);
            feiertag = null;
        }
    };

    // define the date variables and functions
    ctr.monday = (function (today) { return Date.create(today.getFullYear(), today.getMonth(), today.getDate() - ((today.getDay() + 6) % 7)); })(new Date());
    ctr.sunday = getSundayByWeekOffset(0);
    ctr.maxMonday = getMondayByWeekOffset(2);
    ctr.weeks = [];
    ctr.updateWeek = function (incWeek) {
        // dispose old tables and maps
        cleanup();

        // adjust the dates and create the query parameters
        ctr.monday = getMondayByWeekOffset(incWeek);
        ctr.sunday = getSundayByWeekOffset(0);
        var begin = '\'' + new Date(Date.UTC(ctr.monday.getFullYear(), ctr.monday.getMonth(), ctr.monday.getDate())).toISOString() + '\'';
        var end = '\'' + new Date(Date.UTC(ctr.sunday.getFullYear(), ctr.sunday.getMonth(), ctr.sunday.getDate())).toISOString() + '\'';

        // populate the quick access menu
        for (var offset = -8; offset < 4; offset++) {
            var monday = getMondayByWeekOffset(offset);
            if (monday.getTime() > ctr.maxMonday.getTime()) {
                break;
            }
            ctr.weeks.push({
                monday: monday,
                sunday: getSundayByWeekOffset(offset),
                offset: offset
            });
        }

        // fetch all data that depends on the week
        var createReady = function (targetTable, rowChangeHandler) {
            targetTable.ready(function (table) {
                if (table === targetTable) {
                    var rows = table.rows;
                    for (var i = rows.length - 1; i >= 0; i--) {
                        rowChangeHandler(table, null, rows[i]);
                    }
                    table.addRowChangeListener(rowChangeHandler);
                }
            });
        };
        zeitspanne = dataSet.addTable('Zeitspanne', 'Eintritt <= ' + end + ' AND (Austritt IS NULL OR Austritt >= ' + begin + ') AND (' + dataSet.secondaryFilter(Roles.Coaching, Roles.Administration) + ')');
        createReady(zeitspanne, handleZeitspanneRowChange);
        anwesenheit = dataSet.addTable('Anwesenheit', 'Datum BETWEEN ' + begin + ' AND ' + end);
        createReady(anwesenheit, handleAnwesenheitRowChange);
        feiertag = dataSet.addTable('Feiertag', 'Datum BETWEEN ' + begin + ' AND ' + end);
        createReady(feiertag, handleFeiertagRowChange);
    };

    // make sure everything gets cleaned up
    $scope.$on('cleanup', function () {
        dataSet.destroyView(hot);
        cleanup();
    });

    // create the view
    hot = dataSet.createView('Zeitspanne', (function (children) { return children[children.length - 1]; })($element.children()), {
        colHeaders: hotHeaders,
        rowHeaders: false,
        columns: hotColumns,
        cells: hotCells,
        beforeChange: hotBeforeChange
    });
    hot.on('click', hotClick);

    // show the current month
    ctr.updateWeek(0);
})

// controller for an ordinary table view
.controller('TableController', function ($scope, $element, dataSet) {
    var cleanup = false;
    var hot = null;
    var tableName = null;

    // define hot callbacks
    var afterChange = function (changes) {
        // ignore the first load
        if (!changes) {
            return;
        }

        // get all changed rows
        var rows = {};
        for (var i = changes.length - 1; i >= 0; i--) {
            var index = this.runHooks('modifyRow', changes[i][0]);
            var row = this.getSourceDataAtRow(index);
            rows[row.$id] = row;
        }

        // update all changed rows and reflect the status
        var table = dataSet.getTable(tableName);
        $scope.$apply(function () {
            for (var id in rows) {
                table.saveRow(rows[id]).then(null, hot.invalidate);
            }
        });
        hot.invalidate();
    };
    var beforeChange = function (changes, source) {
        // only allow changes by editors
        if (source !== 'edit' && source !== 'undo' && source !== 'redo') {
            return false;
        }
    };
    var afterRenderer = function (TD, row, col, prop) {
        // add the error icon if there is one
        row = this.runHooks('modifyRow', row);
        var sourceRow = this.getSourceDataAtRow(row);
        if (sourceRow.$error && !sourceRow.$action && sourceRow.$error.column === prop && sourceRow.$error.table === tableName) {
            TD.innerHTML += dataSet.errorIcon(sourceRow.$error.message);
        }
    };
    var onClick = function (event) {
        // check if an icon was clicked
        if (!event.target || event.target.tagName !== 'I') {
            return;
        }

        // determine what action should be taken
        var table = dataSet.getTable(tableName);
        var row;
        switch (event.target.className) {
            case 'uk-icon-plus':
                // create the row and invalidate the view
                row = table.newRow();
                for (var i = this.countRows() - 1; i >= 0; i--) {
                    var index = this.runHooks('modifyRow', i);
                    if (row === this.getSourceDataAtRow(index)) {
                        this.selectCell(i, 0, i, this.countCols() - 1);
                        break;
                    }
                }
                $scope.$apply(function () {
                    table.saveRow(row).then(null, hot.invalidate);
                });
                hot.invalidate();
                break;

            case 'uk-icon-trash':
                // check if we can get the id
                var id = Number(event.target.getAttribute('data-row'));
                if (id) {
                    UIkit.modal.confirm('Möchten Sie den Eintrag wirklich unwiderruflich löschen?', function () {
                        row = table.getRowById(id);
                        if (row) {
                            $scope.$apply(function () {
                                // delete the row
                                table.deleteRow(row).then(null, function (error) {
                                    hot.invalidate();
                                    UIkit.modal.alert(error);
                                });
                            });
                            hot.invalidate();
                        }
                    });
                }
                break;
        }
    };
    var rowHeaders = function (index) {
        // return the corner object
        if (index < 0) {
            return dataSet.permissions[tableName].allowNew ? '<i title="Neue Zeile einfügen" data-uk-tooltip="data-uk-tooltip" class="uk-icon-plus"></i>' : '&nbsp;';
        }

        // get the row
        var result = '';
        index = this.runHooks('modifyRow', index);
        var row = this.getSourceDataAtRow(index);

        // reflect the state of the row with an icon
        if (row.$action) {
            result += dataSet.actionIcon;
        }
        else {
            // add the delete icon if allowed
            if (tableName in dataSet.permissions && dataSet.permissions[tableName].allowDelete) {
                result += '<i title="Zeile löschen" data-uk-tooltip="data-uk-tooltip" data-row="' + row.$id + '" class="uk-icon-trash"></i>';
            }

            // only show the error if it cannot be shown in a column
            if (row.$error) {
                var showError = true;
                if (row.$error.table === tableName && row.$error.column) {
                    var columns = this.getSettings().columns;
                    for (var i = columns.length - 1; i >= 0; i--) {
                        if (columns[i].data === row.$error.column) {
                            showError = false;
                            break;
                        }
                    }
                }
                if (showError) {
                    result += dataSet.errorIcon(row.$error.message);
                }
            }
        }

        // return the html
        return result;
    };

    // create the view with a delay to ensure the DOM elements are *really* visible
    var createIfCurrentTab = function () {
        // do nothing if the user switched the menu or the tab
        if (cleanup || $scope.$index !== $scope.main.currentTab) {
            return;
        }

        // either create or rerender the view
        if (!hot) {
            tableName = $scope.tab.name;
            var children = $element.children();
            hot = dataSet.createView(tableName, children[children.length - 1], {
                afterChange: afterChange,
                beforeChange: beforeChange,
                afterRenderer: afterRenderer,
                rowHeaders: rowHeaders
            });
            hot.on('click', onClick);
        }
        else {
            hot.invalidate();
        }
    };
    createIfCurrentTab();

    // watch for tab changes and cleanups
    $scope.$watch('main.currentTab', createIfCurrentTab);
    $scope.$on('cleanup', function () {
        cleanup = true;
        if (hot) {
            dataSet.destroyView(hot);
        }
    });
})

// define the log area controller
.controller('LogController', function (sql, notification, SqlState) {
    var ctr = this;

    // controller variables
    ctr.sql = sql;
    ctr.notification = notification;
    ctr.filter = function (command) {
        return command.state !== SqlState.Completed || (new Date().getTime() - command.lastExecuteTime.getTime()) < 60000;
    };
})

// define the main scope controller
.controller('MainController', function ($scope, sql, Roles, dataSet) {
    var ctr = this;
    var toc = [];

    // define the navigational variables and functions
    ctr.navs = [];
    ctr.currentNav = -1;
    ctr.tabs = [];
    ctr.currentTab = -1;
    ctr.gotoNav = function (index) {
        ArgumentException.check(index, 'index', Number);

        // make sure the index is within range
        if (index < 0 || index >= ctr.navs.length) {
            throw new ArgumentException('Der Navigationsindex ist außerhalb des Bereichs.', 'index');
        }

        // do nothing if we're already there
        if (index === ctr.currentNav) {
            return;
        }

        // load the tables and build the tabs
        $scope.$broadcast('cleanup');
        ctr.tabs = [];
        var tables = toc[index].tables;
        dataSet.load(tables);
        ctr.tabs = toc[index].tabs.slice();
        for (var i = tables.length - 1; i >= 0; i--) {
            var table = tables[i];
            // add a tab if the table is not hidden
            if (!table.hidden) {
                ctr.tabs.push({ name: table.name, type: 'table' });
            }
        }

        // set the tab and nav index
        ctr.currentTab = ctr.tabs.length === 0 ? -1 : 0;
        ctr.currentNav = index;
    };
    ctr.gotoTab = function (index) {
        ArgumentException.check(index, 'index', Number);

        // make sure the index is within range
        if (index < 0 || index >= ctr.tabs.length) {
            throw new ArgumentException('Der Registerkartenindex ist außerhalb des Bereichs.', 'index');
        }

        // switch the current tab
        if (ctr.currentTab !== index) {
            ctr.currentTab = index;
        }
    };

    // query the role membership
    var initialize = function (entries) {
        var roleCommand = 'SELECT 1 AS [public]';
        for (var role in Roles) {
            roleCommand += ', IS_MEMBER(@' + role + ') AS [' + Roles[role] + ']';
        }
        sql.query({
            description: 'Rollenmitgliedschaft abfragen',
            command: roleCommand,
            parameters: Roles
        }).then(function (data) {
            // remove all entry from the toc that can't be accessed
            for (var i = 0; i < entries.length; i++) {
                var entry = entries[i];
                var roles = entry.roles;
                for (var j = roles.length - 1; j >= 0; j--) {
                    if (data[0][roles[j]]) {
                        ctr.navs.push(entry.name);
                        toc.push(entry);
                        break;
                    }
                }
            }

            // make sure something is accessible
            if (ctr.navs.length === 0) {
                throw new UnauthorizedAccessException('Sie haben keine Berechtigung zum Ausführen dieser Anwendung.');
            }

            // select the nav if there is only one
            if (ctr.navs.length === 1) {
                ctr.gotoNav(0);
            }
        });
    };

    // define the content and initialize the app
    initialize([
        {
            name: 'Trainees und Bescheide',
            roles: [Roles.Management, Roles.Administration],
            tables: [
                { name: 'Teilnehmer' },
                { name: 'Zeitspanne', filter: dataSet.secondaryFilter(Roles.Management, Roles.Administration) },
                { name: 'Bescheid', filter: dataSet.secondaryFilter(Roles.Management, Roles.Administration) },
                { name: 'Zeitspanne_Austrittsgrund', hidden: true },
                { name: 'Bescheid_Typ', hidden: true },
                { name: 'Leistungsart', hidden: true },
                { name: 'Einrichtung', hidden: true, filter: dataSet.primaryFilter(Roles.Management, Roles.Administration) }
            ],
            tabs: []
        }, {
            name: 'Anwesenheiten',
            roles: [Roles.Coaching, Roles.Administration],
            tables: [
                { name: 'Teilnehmer', hidden: true },
                { name: 'Einrichtung', hidden: true, filter: dataSet.primaryFilter(Roles.Coaching, Roles.Administration) }
            ],
            tabs: [{ name: 'Teilnehmerliste', type: 'attendance'}]
        }, {
            name: 'Arbeitserprobungen',
            roles: [Roles.JobCoaching],
            tables: [
                { name: 'Standort' },
                { name: 'Praktikum' },
                { name: 'Teilnehmer', hidden: true },
                { name: 'Standort_Bereich', hidden: true },
                { name: 'Praktikum_Kategorie', hidden: true },
                { name: 'Einrichtung', hidden: true }
            ],
            tabs: []
        }, {
            name: 'Planung',
            roles: [Roles.Management, Roles.Accounting],
            tables: [
                { name: 'Planung', filter: dataSet.secondaryFilter(Roles.Management, Roles.Accounting) },
                { name: 'Leistungsart', hidden: true },
                { name: 'Einrichtung', hidden: true, filter: dataSet.primaryFilter(Roles.Management, Roles.Accounting) }
            ],
            tabs: []
        }, {
            name: 'Abrechnung',
            roles: [Roles.Accounting],
            tables: [
                { name: 'Rechnung', hidden: true },
                { name: 'Teilnehmer', hidden: true },
                { name: 'Einheit' },
                { name: 'Leistungsart' },
                { name: 'Kostensatz' },
                { name: 'Verrechnungssatz' }
            ],
            tabs: []
        }, {
            name: 'Systemtabellen',
            roles: [Roles.Administration],
            tables: [
                { name: 'Feiertag' },
                { name: 'Bescheid_Typ' },
                { name: 'Praktikum_Kategorie' },
                { name: 'Standort_Bereich' },
                { name: 'Zeitspanne_Austrittsgrund' },
                { name: 'Einrichtung' }
            ],
            tabs: []
        }
    ]);
});
