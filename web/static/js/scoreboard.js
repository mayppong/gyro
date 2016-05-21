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
