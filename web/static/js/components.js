import Vue from 'vue'

const spinRate = 16 // milliseconds

let nameForm = Vue.component('name-form', {
  props: ['name'],
  template: `
    <form class="name">
      <input type="text" v-model="name" maxlength="3" placeholder="___" />
      <button type="submit" class="send"></button>
    </form>
  `
});

let scoreCounter = Vue.component('score-counter', {
  data: function() {
    return {
      interval: null
    };
  },
  props: {
    score: { type: Number, required: true, default: 0 },
    spm: { type: Number, default: 0 }
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
  template: `<span>Score: {{ prettyScore }}, SPM: {{ prettySPM }}</span>`
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

let scoreboard = Vue.component('scoreboard', {
  props: {
    scoreboard: {
      required: true,
      default: function() { return {} }
    }
  },
  computed: {
    heroics: function() {
      return this.scoreboard.heroics
    },
    legendaries: function() {
      return this.scoreboard.legendaries
    }
  },
  template: `
    <div class="scoreboard">
      <ul class="tabs h-tabs">
        <li>Heroics</li>
        <li>Latest</li>
      </ul>
      <div class="tab-content">
        <table>
          <thead>
            <th>Name</th>
            <th>Score</th>
          </thead>

          <tbody>
            <tr v-for="hero in heroics">
              <td class="name">{{ hero.name }}</td>
              <td><score-counter v-bind:score="hero.score" v-bind:spm="hero.spm"></score-counter></td>
            </tr>

            <tr v-for="legend in legendaries">
              <td class="name">{{ legend.name }}</td>
              <td><score-counter v-bind:score="legend.score" v-bind:spm="legend.spm"></score-counter></td>
            </tr>
          </tbody>

      </div>
    </div>
  `
})
