
// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import "../css/app.scss"

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import deps with the dep name or local files with a relative path, for example:
//
//     import {Socket} from "phoenix"
//     import socket from "./socket"
//
import "phoenix_html"
import * as Vue from "vue"

// Import local files
//
// Local files can be imported directly using relative
// paths "./socket" or full ones "web/static/js/socket".

import socket from "./socket"
import * as Components from "./components"

const ShwarmaSpin = Vue.createApp({
  data: function() {
    return {
      socket: socket,
      arenaChannel: null,
      squadChannel: null,
      store: {
        arena: {},
        spinner: {},
        squad: {}
      }
    };
  },
  computed: {
    arena: function() {
      return this.store.arena
    },
    spinner: function() {
      return this.store.spinner
    },
    squad: function() {
      return this.store.squad
    }
  },
  created: function() {
    this.init()
  },
  methods: {
    init() {
      var self = this
      this.arenaChannel = this.socket.channel('arenas:lobby', {})

      this.arenaChannel.join()
        .receive('ok', resp => { console.log('Joined successfully', resp) })
        .receive('error', resp => { console.log('Unable to join', resp) })

      this.arenaChannel.on('introspect', (resp) => {
        self.store.spinner = resp.spinner
        self.store.arena = resp.arena
      })
    },
    intro(newName) {
      if (newName != '') {
        var self = this
        this.arenaChannel
          .push('intro', { name: newName })
          .receive('ok', resp => {
            self.store.spinner.name = resp.name
          })
          .receive('error', resp => { console.log('Unable to set name', resp) })
      }
    },
    join(squadName) {
      this.leave()

      if (squadName) {
        debugger;
        var self = this
        this.squadChannel = this.socket.channel('arenas:squads:' + squadName)
        this.squadChannel.join()
          .receive('ok', resp => {
            self.squadChannel.on('introspect', resp => {
              self.store.squad = resp.squad
            })
          })
          .receive('error', resp => {
            self.squadChannel = null
          })
      }
    },
    leave() {
      if (this.squadChannel) {
        this.squadChannel.leave()
        this.squadChannel = null;
        this.store.squad = { name: this.squad.name }
      }
    }
  }
});

ShwarmaSpin.component('spinner', Components.spinner);
ShwarmaSpin.component('name-form', Components.nameForm);
ShwarmaSpin.component('identity', Components.identity);
ShwarmaSpin.component('message', Components.message);
ShwarmaSpin.component('chat-room', Components.chatRoom);
ShwarmaSpin.component('scoreboard', Components.scoreboard);

ShwarmaSpin.mount('#shwarmaspin');