'use strict'

Ctrl = require "./ctrl.coffee"

class AppCtrl extends Ctrl
  @$inject: ['$scope', '$stateParams', '$state', "Restangular", "$timeout", "$famous", "$window", "$http", "$firebase", "$ionicPopup","$firebaseSimpleLogin"]
  sendInvite: (to)=>
    console.log "send invite to #{to}"
    from = @scope.uuid
    @scope.invite = @firebase(new Firebase("https://famousduel.firebaseio.com/challenges/#{to}/#{from}"))
    @scope.invite.$set @scope.user
    @scope.invite.$on "change", =>
      if @scope.invite.status =="accept"
        @startDuel from,to
        @scope.invite.$update
          status: "started"
  startDuel: (from,to)=>
    if from==@scope.uuid
      @scope.me = 0
      @scope.other = 1
    else
      @scope.me = 1
      @scope.other = 0
    @scope.remoteGameState = {}
    @scope.remoteGameState[@scope.me] = 
      timelineBullet: 0
      state: "alive"
    @scope.remoteGameState[@scope.other] = 
      timelineBullet: 0
      state: "alive"
    @scope.gameStateMe = @firebase(new Firebase("https://famousduel.firebaseio.com/games/#{from}/#{to}/#{@scope.me}"))
    @scope.gameStateMe.$bind @scope, "remoteGameState.#{@scope.me}"
    @scope.gameStateOther = @firebase(new Firebase("https://famousduel.firebaseio.com/games/#{from}/#{to}/#{@scope.other}"))
    @scope.gameStateOther.$bind @scope, "remoteGameState.#{@scope.other}"
    @startGame()
  accept: (k,c)=>
    c.status = "accept"
    @startDuel k,@scope.uuid
    
  managePresence: (user, cb)=>
  
    # since I can connect from multiple devices or browser tabs, we store each connection instance separately
    # any time that connectionsRef's value is null (i.e. has no children) I am offline
    myConnectionsRef = new Firebase("https://famousduel.firebaseio.com/users/#{user.id}/connections")

    # stores the timestamp of my last disconnect (the last time I was seen online)
    userRef = new Firebase("https://famousduel.firebaseio.com/users/#{user.id}")
    lastOnlineRef = new Firebase("https://famousduel.firebaseio.com/users/#{user.id}/lastOnline")
    connectedRef = new Firebase("https://famousduel.firebaseio.com/.info/connected")
    connectedRef.on "value", (snap) =>
      if snap.val() is true
  
        # We're connected (or reconnected)! Do anything here that should happen only if online (or on reconnect)
  
        # add this device to my connections list
        # this value could contain info about the device or a timestamp too
        con = myConnectionsRef.push(user, (err,v)=>
          @scope.uuid = user.id+con.name()
          cb?()
        )
        
        # when I disconnect, remove this device
        con.onDisconnect().remove()
        userRef.onDisconnect().remove()
        
        # when I disconnect, update the last time I was seen online
        # lastOnlineRef.onDisconnect().set Firebase.ServerValue.TIMESTAMP
      return
  
    
  constructor: (@scope, @stateParams, @state, @Restangular, @timeout, @famous, @window, @http, @firebase, @ionicPopup, @firebaseSimpleLogin) ->
    super @scope
    
    @scope.users = @firebase(new Firebase("https://famousduel.firebaseio.com/users"))
    @scope.users.$bind @scope, "remoteUsers"
    
    @scope.loginObj = @firebaseSimpleLogin(new Firebase("https://famousduel.firebaseio.com/"));    
    @scope.loginObj.$login 'anonymous',
      rememberMe: true
    .then (user)=>
      @scope.user = user
      @managePresence user, =>
        @scope.challenges = @firebase(new Firebase("https://famousduel.firebaseio.com/challenges/#{@scope.uuid}"))
        @scope.challenges.$bind @scope, "remoteChallenges"

    @scope.width = $(window).width()
  reset: =>
    @startGame()
  loop: =>
    if not @start
      return
    if @done
      return
    @timeout =>
      LR = @scope.remoteGameState[@scope.me].timelineBullet
      RL = 0
      if @scope.remoteGameState
        RL = @scope.remoteGameState[@scope.other].timelineBullet
      if RL>0.1 and LR>0.1 and RL+LR>0.9
        @timeout =>
          @scope.remoteGameState[@scope.me].state = "alive"
          @scope.remoteGameState[@scope.me].timelineBullet = 0
        @timelineBulletLR = new @Transitionable(0)
        @timelineBulletRL = new @Transitionable(0)
      if LR>0.9 or RL>0.9
        if RL >= LR
          @timeout =>
            @scope.remoteGameState[@scope.me].state = "dead"
          # @done = true
          # @start = false
          console.log "You Lose!"
        else
          # @done = true
          # @start = false
          console.log "You Win!"
  startGame: =>
    @done = false
    @start = true

    @timeout =>
      @scope.remoteGameState[@scope.me].state = "alive"
      @scope.remoteGameState[@scope.me].timelineBullet = 0

    @timeline = new @Transitionable(0)
    @timelineBulletLR = new @Transitionable(0)
    @timelineBulletRL = new @Transitionable(0)
    
    @timeline.set 1, duration: 5000
  shoot: =>
    if not @start
      return
    time = @timeline.get()
    if time < 0.3
      console.log "can't shoot yet"
    else
      @timeline.set 0
      @timeline.set 1, duration: 3000
      @diff = time - 0.3
      @timeout =>
        @scope.remoteGameState[@scope.me].state = "shoot"
        @moveBulletLR(@diff)
  moveBulletLR: (@diff)=>
    # console.log "movebullte"
    # @timelineBulletLR.set 0
    cur = @timelineBulletLR.get()
    @timelineBulletLR.set cur
    @timelineBulletLR.set 1, duration: (1-cur)*20000*@diff, =>
      @timeout =>
        @scope.remoteGameState[@scope.me].state = "alive"
        @timelineBulletLR.set 0
  timeBulletLR: =>
    if not @start
      return
    time = @timelineBulletLR.get()
    @timeout =>
      time = @timelineBulletLR.get()
      @scope.remoteGameState[@scope.me].timelineBullet = time
    return time
  timeBulletRL: =>
    if not @start
      return
    time = @scope.remoteGameState[@scope.other].timelineBullet
    @timelineBulletRL.set time
    return time
  time: =>
    if not @start
      return
    return @timeline.get()
angular.module('simplecareersApp').controller('AppCtrl', AppCtrl)
