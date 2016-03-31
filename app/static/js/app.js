'use strict';  

var myApp = angular.module('myApp', ['ngRoute', 'ngAnimate', 'LocalStorageModule', 'ui.bootstrap']);

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