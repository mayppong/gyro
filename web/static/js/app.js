// Brunch automatically concatenates all files in your
// watched paths. Those paths can be configured at
// config.paths.watched in "brunch-config.js".
//
// However, those files will only be executed if
// explicitly imported. The only exception are files
// in vendor, which are never wrapped in imports and
// therefore are always executed.

// Import dependencies
//
// If you no longer want to use a dependency, remember
// to also remove its path from "config.paths.watched".
import "phoenix_html"
import Vue from "vue"

// Import local files
//
// Local files can be imported directly using relative
// paths "./socket" or full ones "web/static/js/socket".

import socket from "./socket"
import components from "./components"

new Vue({
  el: 'body',
  data: {
    socket: socket,
    arenaChannel: null,
    squadChannel: null,
    store: {
      arena: {},
      spinner: {},
      squad: {}
    },
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
    this._init()
  },
  methods: {
    _init() {
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
    intro() {
      if (this.spinner.name != '') {
        this.arenaChannel
          .push('intro', { name: this.spinner.name })
      }
    },
    join() {
      if (this.squad.name != '') {
        var self = this
        this.squadChannel = this.socket.channel('arenas:squads:' + this.squad.name)
        this.squadChannel.join()
          .receive('ok', resp => {
            self.squadChannel.on('introspect', resp => {
              self.store.squad = resp
            })
          })
          .receive('error', resp => {
            self.squadChannel = null
          })
      }
    }
  }
})
