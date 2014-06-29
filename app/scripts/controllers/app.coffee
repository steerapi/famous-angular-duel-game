'use strict'

Ctrl = require "./ctrl.coffee"

class AppCtrl extends Ctrl
  @$inject: ['$scope', '$stateParams', '$state', "Restangular", "$timeout", "$famous", "$window", "$http", "$firebase"]
  constructor: (@scope, @stateParams, @state, @Restangular, @timeout, @famous, @window, @http, @firebase) ->
    super @scope
    
    # @duelRef = new Firebase("https://famousduel.firebaseio.com/duel");
    # auth = new FirebaseSimpleLogin @duelRef,(e,user)=>
    #   @scope.userid = user.id
    # auth.login 'anonymous',
    #   rememberMe: true
    # @scope.people = @firebase(duelRef)
    
    @scope.width = $(window).width()
    @start = false
    @timeout =>
      @startGame()
    , 1000
    
  reset: =>
    @startGame()
  loop: =>
    if not @start
      return
    if @done
      return
    LR = @timelineBulletRL.get()
    RL = @timelineBulletLR.get()
    if RL>0.1 and LR>0.1 and RL+LR>0.9
      @timeout =>
        @startGame()
        # @scope.stateA = "alive"
        # @scope.stateB = "alive"
        # @timelineBulletRL.set 0
        # @timelineBulletLR.set 0
        # @timeline.set 0
    if @timelineBulletRL.get()>0.9 or @timelineBulletLR.get()>0.9
      if @timelineBulletRL.get() >= @timelineBulletLR.get()
        @done = true
        @timeout =>
          @scope.stateA = "dead"
          @start = false
          # alert("You Lose!", =>
          #   @reset()
          # )
      else
        @done = true
        @timeout =>
          @scope.stateB = "dead"
          @start = false
          # alert("You Win!", =>
          #   @reset()
          # )
  startGame: =>
    @timeout =>
      @scope.stateB = "shoot"
      @moveBulletRL()
    , 1000+Math.random()*1000
    @done = false
    @start = true
    @scope.stateA = "alive"
    @scope.stateB = "alive"
    @timeline = new @Transitionable(0)
    @timelineBulletLR = new @Transitionable(0)
    @timelineBulletRL = new @Transitionable(0)
    @timeline.set 1, duration: 5000
  ai: =>
    return 0.3+Math.random()*0.1
  shoot: =>
    if not @start
      return
    time = @timeline.get()
    if time < 0.3
      console.log "can't shoot yet"
    else
      # obj = {}
      # obj[@scope.userid] = time
      # @duelRef.update obj
      @scope.stateA = "shoot"
      @moveBulletLR()
      console.log "shoot", time
  moveBulletRL: =>
    @timelineBulletRL.set 1, duration: 500
  moveBulletLR: =>
    @timelineBulletLR.set 1, duration: 500
  timeBulletLR: =>
    if not @start
      return
    return @timelineBulletLR.get()
  timeBulletRL: =>
    if not @start
      return
    return @timelineBulletRL.get()
  time: =>
    if not @start
      return
    return @timeline.get()
angular.module('simplecareersApp').controller('AppCtrl', AppCtrl)
