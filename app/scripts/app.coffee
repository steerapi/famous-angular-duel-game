'use strict'

require "./extensions/capitalize.coffee"

angular
  .module('simplecareersApp', [
    'ui.router',
    'restangular',
    'famous.angular',
    'firebase'
  ])
  .config([
    '$locationProvider'
    'RestangularProvider'
  	'$stateProvider'
    '$urlRouterProvider'
  	($locationProvider, RestangularProvider, $stateProvider, $urlRouterProvider, config) ->
      $locationProvider.html5Mode(false);        
      RestangularProvider.setRestangularFields
        id: "_id"
      RestangularProvider.setBaseUrl "http://simplecareers-test.apigee.net/angel/"
        
      $urlRouterProvider.otherwise "/app"
    
      $stateProvider
      .state('app',
        url: "/app",
        views: 
          {
            'main': {
              templateUrl: "/views/app.html",
              controller: "AppCtrl"
            }
          }
      )

  ])

require "./controllers/app.coffee"

angular.bootstrap(document, ['simplecareersApp']);