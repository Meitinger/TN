'use strict';

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

// define angular module
angular.module('tn', [])

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
        if (angular.isDefined(args.parameters)) {
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
            jQuery.extend(config, {
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
        var allowError = args.allowError == true;
        var singleSet = forceSingleSet || args.singleSet == true;

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
	                        angular.forEach(data, function (value, key) {
	                            if (!angular.isObject(value) || !angular.isNumber(value.RecordsAffected) || !angular.isArray(value.Records))
	                                throw new InvalidDataException('Ungültiges Recorset.');
	                            angular.forEach(value.Records, function (value, key) {
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
            sql: args.command.replace(/\b@(\w+)\b/g, function (match, name) { return args.parameters[name]; }),
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
            if (keys != 1)
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
                angular.forEach(data, function (value, key, obj) {
                    obj[key] = changeCase(value);
                });
            }
            else
                data = changeCase(data);
            return data;
        });
    };
})

// notify service
.service('notify', function ($http, $timeout, $q) {

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
        var handleError = function (message) {
            // set the error and reschedule the query
            error = message;
            $timeout(query, 10000);
        };

        $http({
            method: 'GET',
            url: 'notify.ashx',
            params: { lastEventId: lastEventId },
            timeout: 60000
        }).then(
			function (response) {
			    // parse the data
			    var data = response.data;
			    try {
			        if (!angular.isObject(data))
			            throw new InvalidDataException('Kein Ereignisobjekt empfangen.');
			        if (!angular.isNumber(data.LastEventId))
			            throw new InvalidDataException('Rückgabeobjekt enthält keine Ereignisnummer.');
			        if (data.LastEventId < 0)
			            throw new InvalidDataException('Die Ereignisnummer ist negativ.');
			        if (lastEventId > -1)
			    }
			    catch (e) {
			        // handle the error
			        if (e instanceof InvalidDataException) {
			            handleError(e.message);
			            return;
			        }
			        throw e;
			    }

			    // set the last event id and reset the error
			    var first = lastEventId == -1;
			    error = null;
			    lastEventId = data.LastEventId;
			    lastSyncTime = new Date();

			    // notify any readiness listeners
			    if (first)
			        readyEvent.resolve();

			    // requery
			    query();
			},
			function (response) {
			    handleError('Übertragungsfehler "' + response.statusText + '".');
			}
		);
    };

    // define the function object
    var notify = function (fn, filter) {
        // check the input arguments
        if (!angular.isFunction(fn))
            throw new ArgumentException('Funktionswert erwartet.', 'fn');
        if (angular.isDefifined(filter) && !angular.isString(filter))
            throw new ArgumentException('Filter muss eine Zeichenkette oder nicht angegeben sein.', 'filter');

        // get the next id and increment the counter
        var id = nextNotificationId++;

        // get the deferred object and its promise's notify function
        var deferred = $q.defer();
        var promise = deferred.promise;
        promise.then(null, null, fn);

        // add the notifcation
        notifications[id] = {
            filter: filter,
            deferred: deferred
        };

        // set the promise id and return id
        promise.$notifyId = id;
        return promise;
    }

    // define the cancellation method
    notify.cancel = function (promise) {
        if (promise && promise.$notifyId in notifications) {
            var notification = notifications[promise.$notifyId];
            delete notifications[promise.$notifyId];
            notification.deferred.reject('cancelled');
            return true;
        }
        return false;
    };

    // define the readiness callback function
    notify.ready = function (fn) {
        var promise = readyEvent.promise;
        promise.then(fn);
        return promise;
    };

    // define the status functions
    notify.getError = function () {
        return error;
    }
    notify.getLastSyncTime = function () {
        return lastSyncTime;
    }
    notify.getLastEventTime = function () {
        return lastEventTime;
    }

    // initialize and return the notify function object
    query();
    return notify;
})
.factory('table', function (sql, notify) {
    return function (name, filter) {
    };
})
.controller('LogController', function (sql, notify) {
    this.sql = sql;
    this.notify = notify;
    this.limit = 10;
    this.limitOptions = [10, 50, 100, 500, 1000];
    this.offset = 0;
})
.controller('MainController', function ($scope, $window, sql) {
    $scope.Math = $window.Math;
    this.test = 'init';
    this.exec = function () {
        sql.query({
            description: 'Einrichtung abfragen',
            command: 'SELECT * FROM Einrchtung WHERE ID = @ID',
            parameters: { 'ID': 2 },
            allowError: true,
            allowReview: true
        }).then(
	        function (records) {

	        },
	        function (error) {
	        }
	    );
    };
});
