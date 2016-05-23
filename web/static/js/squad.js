import Vue from 'vue'
import socket from './socket'

let squadScore = Vue.component('squad-score', {
  data: function() {
    return {
      score: 0,
      spm: 0,
    }
  },
  props: ['squadChannel'],
  watch: {
    squadChannel: function(channel) {
      channel.on("introspect", resp => {
        this.score = resp.score
        this.spm = resp.spm
      })
    }
  },
  template: `<score-counter v-bind:score="score" v-bind:spm="spm"></score-counter>`
})
