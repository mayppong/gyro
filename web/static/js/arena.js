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
  beforeCompile: function() {
    arena.on('introspect', resp => {
      console.log(resp)
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
    return {
      messages: [],
      input: ''
    }
  },
  created: function() {
    arena.on('shout', payload => {
      this.messages.push(payload)
    })
  },
  computed: {
    timestamp: function() {
      return (new Date()).toUTCString()
    }
  },
  methods: {
    submit: function() {
      arena.push('shout', { message: this.input })
      this.input = ''
    }
  },
  template: `
    <div class="chat">
      <ul class="chat-history">
        <li v-for="message in messages">[{{ timestamp }}] {{ message.from || '___' }}: {{ message.message }}</li>
      </ul>
      <form v-on:submit.prevent="submit" class="chat-input">
        <input type="text" v-model="input" />
        <button type="submit" class="send"></button>
      </form>
    </div>
  `
})
