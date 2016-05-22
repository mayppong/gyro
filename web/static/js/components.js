import Vue from 'vue'

const spinRate = 16 // milliseconds

let scoreCounter = Vue.component('score-counter', {
  data: function() {
    return {
      interval: null
    };
  },
  props: {
    score: { type: Number, required: true, default: 0 },
    spm: { type: Number, default: 1 }
  },
  beforeCompile: function() {
      this.interval = setInterval(() => {
        this.score += this.increment
      }, spinRate)
  },
  computed: {
    prettyScore: function() {
      return this.score.toFixed(3)
    },
    prettySPM: function() {
      return this.spm.toFixed(1)
    },
    increment: function() {
      return ((this.spm / 60) * (spinRate / 1000))
    }
  },
  template: `<p>Score: {{ prettyScore }}, SPM: {{ prettySPM }}</p>`
})

let chatRoom = Vue.component('chat-room', {
  data: function() {
    return {
      messages: [],
      input: ''
    }
  },
  props: ['channel'],
  computed: {
    timestamp: {
      cache: false,
      get: function() {
        return (new Date()).toUTCString()
      }
    }
  },
  methods: {
    submit: function() {
      this.channel.push('shout', { message: this.input })
      this.input = ''
    }
  },
  created: function() {
    this.channel.on('shout', payload => {
      this.messages.push(payload)
    })
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
