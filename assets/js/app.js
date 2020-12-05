
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
      if (this.spinner.newName != '') {
        var self = this
        this.arenaChannel
          .push('intro', { name: this.spinner.newName })
          .receive('ok', resp => {
            self.store.spinner.name = resp.name
            console.log('name set', resp)
          })
          .receive('error', resp => { console.log('Unable to set name', resp) })
      }
    },
    join() {
      this.leave()

      if (this.squad.newName) {
        var self = this
        this.squadChannel = this.socket.channel('arenas:squads:' + this.squad.newName)
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
