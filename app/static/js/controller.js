'use strict';


angular.module('myApp')
  .controller('HomeCtrl', function($scope, $http, $location, dataShare, localStorageService, $timeout) {

    $scope.submit = function() {

        var data = {
            'query': $scope.searchBox
        }

        var config = {
            headers : {
                'Content-Type': 'application/x-www-form-urlencoded;charset=utf-8;'
            }
        }

        $http.post('/query', data)
            .success(function (response) {
             
                $scope.status = response.status
                $scope.$watch('status', function () {
                    if ($scope.status == "Error!") {
                        $location.path('/not_found');  
                    } else {
                        dataShare.sendData(data);
                        localStorageService.set('params',data);
                        $timeout(function() {
                            $location.path('/queryOut');
                        }, 500);
                    }
                });
            })
            .error(function (data, status, header, config) {
                $location.path('/');
                $scope.ServerResponse = "Data: " + data +
                    "<hr />status: " + status +
                    "<hr />headers: " + header +
                    "<hr />config: " + config;
        });

    };

    var _selected;

    $scope.selected = undefined;
      $scope.queries = ['People killed in Paris Bombing', 'People killed in Bamako Shooting'];
  });

angular.module('myApp')
  .controller('QueryCtrl', function($scope, $http, $location, dataShare, localStorageService, $timeout, $sce, $uibModal) {

    $scope.params = localStorageService.get('params');
    $scope.out = ''
    $scope.searchBox = $scope.params.query
    $scope.result = 'False';
    //$scope.current = '';
    call();

    function call(){
        $http.post('/query', $scope.params)
            .success(function (response) {

                $scope.response = response

                if ($scope.response.status == "Error!") {
                        $location.path('/not_found');  
                    } else { 
                        if($scope.response.data.length != 0){
                            $scope.out = response.data
                            $scope.result = 'True';
                        }
                        else{
                            if($scope.response.data.length == 0){
                                $timeout(call(), 1000);
                            } 
                        }
                    }
            })
            .error(function (data, status, header, config) {
                $location.path('/');
                $scope.ServerResponse = "Data: " + data +
                    "<hr />status: " + status +
                    "<hr />headers: " + header +
                    "<hr />config: " + config;
        });
    }

    $scope.submit = function() {

        var data = {
            'query': $scope.searchBox
        }

        var config = {
            headers : {
                'Content-Type': 'application/x-www-form-urlencoded;charset=utf-8;'
            }
        }

        $http.post('/query', data)
            .success(function (response) {

                $scope.response = response
                $scope.$watch('response', function () {
                    if ($scope.response.status == "Error!") {
                        $location.path('/not_found');  
                    } else {
                        dataShare.sendData(data);
                        localStorageService.set('params',data);
                        if($scope.response.data.length > 0){
                            $scope.out = $scope.response.data
                        }else{
                            $timeout(function() {
                                $scope.out = $scope.response.data
                            }, 500);
                        }
                    }
                });
            })
            .error(function (data, status, header, config) {
                $location.path('/');
                $scope.ServerResponse = "Data: " + data +
                    "<hr />status: " + status +
                    "<hr />headers: " + header +
                    "<hr />config: " + config;
        });

    }; 

    var _selected;

    $scope.selected = undefined;
    $scope.queries = ['People killed in Paris Bombing', 'People killed in Bamako Shooting'];

    $scope.linkClick = function(link){
        $scope.current = $sce.trustAsResourceUrl(link);
    };
   
    $scope.popup = function (link){
                var uibModalInstance = $uibModal.open({
                    templateUrl: 'index.html',
                });
    }
    
});
