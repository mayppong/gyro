import socket from './socket'
import Vue from 'vue'

// Now that you are connected, you can join channels with a topic:
let arena = socket.channel("arenas:lobby", {})

arena.join()
  .receive("ok", resp => { console.log("Joined successfully", resp) })
  .receive("error", resp => { console.log("Unable to join", resp) })

let spinnerScore = Vue.component('spinner-score', {
  data: function() {
    return {
      score: 0,
      spm: 1
    }
  },
  created: function() {
    arena.on('introspect', resp => {
      this.score = resp.spinner.score
      this.spm = resp.spinner.spm
    })
  },
  template: `<score-counter v-bind:score="score" v-bind:spm="spm"></score-counter>`
})

let spinnerName = Vue.component('spinner-name', {
  data: function() {
    return { name: '' };
  },
  methods: {
    submit: function() {
      arena
        .push('intro', { name: this.name })
        .receive('ok', resp => {
          this.name = resp.name
        })
    }
  },
  template: `
    <form v-on:submit.prevent="submit" class="name">
      <input type="text" v-model="name" maxlength="3" placeholder="___" />
      <button type="submit" class="send"></button>
    </form>
  `
});

let arenaChat = Vue.component('arena-chat', {
  data: function() {
    return { arenaChannel: arena }
  },
  template: `
    <chat-room v-bind:channel.once="arenaChannel"></chat-room>
  `
})

let arenaScoreboard = Vue.component('arena-scoreboard', {
  data: function() {
    return { heroics: [] }
  },
  created: function() {
    arena.on('introspect', resp => {
      this.heroics = resp.arena.heroic_spinners
    })
  },
  template: `
    <scoreboard v-bind:heroics="heroics"></scoreboard>
  `
})
