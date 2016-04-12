'use strict';  

var myApp = angular.module('myApp', ['ngRoute', 'ngAnimate', 'LocalStorageModule', 'ui.bootstrap', 'ngMaterial', 'ngMessages', 'angular-google-analytics']);

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

myApp.config(function (AnalyticsProvider) {
    
    AnalyticsProvider.logAllCalls(true);
    AnalyticsProvider.startOffline(true)
    AnalyticsProvider.useAnalytics(false);
    AnalyticsProvider.setAccount('UA-55160701-3');

    });