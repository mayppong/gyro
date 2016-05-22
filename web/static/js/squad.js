import Vue from 'vue'
import socket from './socket'

let squadChannel;

let squadName = Vue.component('squad-name', {
  data: function() {
    return { name: '' }
  },
  props: ['squadChannel'],
  methods: {
    submit: function() {
      if (this.name != '') {
        this.squadChannel = socket.channel('arenas:squads:' + this.name)
        this.squadChannel.join()
          .receive('ok', resp => {
          })
          .receive('error', resp => {
            this.squadChannel = null
          })
      }
    }
  },
  template: `
    <form v-on:submit.prevent="submit" class="name">
      <input type="text" v-model="name" maxlength="3" placeholder="___" />
      <button type="submit" class="send"></button>
    </form>
  `
})

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
