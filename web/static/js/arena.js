import Vue from 'vue'

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
