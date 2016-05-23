import Vue from 'vue'

let spinnerScore = Vue.component('spinner-score', {
  data: function() {
    return {
      score: 0,
      spm: 1
    }
  },
  props: ['channel'],
  created: function() {
    this.channel.on('introspect', resp => {
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
  props: ['channel'],
  methods: {
    submit: function() {
      this.channel
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
