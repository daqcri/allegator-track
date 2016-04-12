'use strict';  

var myApp = angular.module('myApp', ['ngRoute', 'ngAnimate', 'LocalStorageModule', 'ui.bootstrap', 'ngMaterial', 'ngMessages']);

myApp.config(['$routeProvider', 
     function($routeProvider) {

         $routeProvider.
             when('/', {
                 templateUrl: 'static/partials/home.html',
                 controller: 'HomeCtrl',    
             }).
             when('/queryOut', {
                 templateUrl: 'static/partials/queryOut.html',
                 controller: 'QueryCtrl',
             }).
             when('/not_found', {
                 templateUrl: 'static/partials/404.html',
             }).
             otherwise({
                 redirectTo: '/'
             });
    }]);

myApp.run(run);

run.$inject = ['$rootScope', '$location', '$window'];
function run($rootScope, $location, $window) {
        // initialise google analytics
    $window.ga('create', 'UA-55160701-3', 'auto');
 
  $rootScope
        .$on('$stateChangeSuccess',
            function(event){
 
                if (!$window.ga)
                    return;
 
                $window.ga('send', 'pageview', { page: $location.path() });
        });

    $rootScope.$on('$viewContentLoaded', function(event) {
        $window.ga('send', 'pageview', { page: $location.url() });
    });
}