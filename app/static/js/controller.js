'use strict';


angular.module('myApp')
  .controller('HomeCtrl', function($scope, $http, $location, dataShare, localStorageService, $timeout) {

    $scope.$on('$viewContentLoaded', function(event) {
        $window.ga('send', 'pageview', { page: $location.url() });
    });

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
      $scope.queries = ['People killed in Paris Bombing', 'People killed in Boston Bombing', 'Name of Suspects in Boston Bombing', 'Number of stadium attackers in Paris Bombings',
    'Locations Attacked in Paris Bombing', 'Time of Attacks during Paris Bombing', 'Number of attacks in concert halls during Paris Bombing', 'People killed in Concert Hall during Paris Bombing',
    'Name of suspects in Toulouse Bombing', 'People killed in Toulouse Bombing', 'Children Killed in Toulouse Bombing', 'Number of explosions during Boston Bombings', 'Number of hostages during Paris Bombings',
    'Number of attacks during Paris Bombings', 'Locations Attacked in Paris Bombing', 'Suspects identified in Paris Bombing'];
  });

angular.module('myApp')
  .controller('QueryCtrl', function($scope, $http, $location, dataShare, localStorageService, $timeout, $sce, $uibModal) {

    $scope.$on('$viewContentLoaded', function(event) {
        $window.ga('send', 'pageview', { page: $location.url() });
    });

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
    $scope.queries = ['People killed in Paris Bombing', 'People killed in Boston Bombing', 'Name of Suspects in Boston Bombing', 'Number of stadium attackers in Paris Bombings',
    'Locations Attacked in Paris Bombing', 'Time of Attacks during Paris Bombing', 'Number of attacks in concert halls during Paris Bombing', 'People killed in Concert Hall during Paris Bombing',
    'Name of suspects in Toulouse Bombing', 'People killed in Toulouse Bombing', 'Children Killed in Toulouse Bombing', 'Number of explosions during Boston Bombings', 'Number of hostages during Paris Bombings',
    'Number of attacks during Paris Bombings', 'Locations Attacked in Paris Bombing', 'Suspects identified in Paris Bombing'];
    $scope.linkClick = function(link){
        $scope.current = $sce.trustAsResourceUrl(link);
        poptastic($scope.current)
    };
   
    $scope.popup = function (link){
                var uibModalInstance = $uibModal.open({
                    templateUrl: 'index.html',
                });
    }
    
    $scope.goTo = function(link){
        window.open(link, '_blank')
    };

    $scope.home = function(){
        $location.path('/')
    }

    var newwindow; function poptastic(url){
    newwindow=window.open(url,'name', 'height=800,width=1020,scrollbars=yes');
    if (window.focus) {newwindow.focus()}}

});
