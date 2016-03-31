myApp.service("PromiseUtils", function($q) {
    return {
        getPromiseHttpResult: function (httpPromise) {
            var deferred = $q.defer();
            httpPromise.success(function (data) {
                deferred.resolve(data);
            }).error(function () {
                deferred.reject(arguments);
            });
            return deferred.promise;
        }
    }
})