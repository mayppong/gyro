const spinRate = 16 // milliseconds

export let spinner = {
  props: {
    score: {
      type: Number,
      required: true,
      default: 0
    },
    spm: {
      type: Number,
      default: 0
    }
  },
  data: function() {
    return {
      currentScore: 0,
      interval: null
    };
  },
  created: function() {
    this.currentScore = this.score;
    this.interval = setInterval(() => {
      this.currentScore += this.increment
    }, spinRate)
  },
  computed: {
    prettyScore: function() {
      return this.currentScore.toFixed(3)
    },
    prettySPM: function() {
      return this.spm.toFixed(1)
    },
    increment: function() {
      return ((this.spm / 60) * (spinRate / 1000))
    }
  },
  template: `
    <span>
      <span class="score">{{ prettyScore }}</span> &gt; <span class="spm">{{ prettySPM }}</span>
    </span>
  `
};

export let nameForm = {
  data: function() {
    return { name: '' };
  },
  methods: {
    updateName: function() {
      this.$emit('update-name', this.name);
    }
  },
  template: `
    <form class="name-picker h-fill" @submit.prevent="updateName">
      <input type="text" class="fill" v-model="name" maxlength="3" placeholder="___" />
      <button type="submit">&gt;&gt;</button>
    </form>
  `
};

export let identity = {
  props: ['name', 'squad'],
  computed: {
    identity: function(){
      let s = '';
      if (this.name){
        s += '@'+this.name;
      }
      if (this.squad){
        s += '#'+this.squad;
      }
      return s;
    }
  },
  template: `<span class="identity">{{ identity }}</span>`
};

export let message = {
  props: ['message'],
  computed: {
    timestamp: function() {
      var date = new Date();
      return date.getHours() + ":" + date.getMinutes();
    }
  },
  template: `
    <div class="message">
      <div class="message-header">
        <span class="timestamp">{{ timestamp }}</span>&nbsp;
        <identity :name="message.from"
          :squad="message.squad"></identity>
      </div>
      <div class="message-body">{{ message.message }}</div>
    </div>
  `
};

export let chatRoom = {
  props: ['channel'],
  data: function() {
    return {
      messages: [],
      input: ''
    }
  },
  created: function() {
    this.channel.on("shout", (resp) => {
      this.messages.push(resp);
    });
  },
  methods: {
    shout: function() {
      this.channel.push("shout", {message: this.input});
      this.input = "";
    }
  },
  template: `
    <div class="messages fill">
      <message v-for="message in messages"
        :message="message"></message>
    </div>
    <form class="new-message h-fill" @submit.prevent="shout">
      <input class="fill" type="text" name="message" v-model="input" />
      <button type="submit">&gt;&gt;</button>
    </form>
  `
};

export let scoreboard = {
  props: {
    scoreboard: {
      required: true,
      default: function() {
        return {};
      }
    }
  },
  data: function() {
    return { view: 'heroics' }
  },
  computed: {
    heroics: function() {
      return this.scoreboard.heroics
    },
    legendaries: function() {
      return this.scoreboard.legendaries
    },
    latest: function() {
      return this.scoreboard.latest
    }
  },
  template: `
    <div>
      <ul class="tabs">
        <li class="tab"
          v-if="view != 'legendaries'"
          v-on:click="view = 'legendaries'">Legends</li>
        <li class="tab selected"
          v-if="view == 'legendaries'">&gt;Legends&lt;</li>
        <li class="tab"
          v-if="view != 'heroics'"
          v-on:click="view = 'heroics'">Heroes</li>
        <li class="tab selected"
          v-if="view == 'heroics'">&gt;Heroes&lt;</li>
        <li class="tab"
          v-if="view != 'latest'"
          v-on:click="view = 'latest'">Latest</li>
        <li class="tab selected"
          v-if="view == 'latest'">&gt;Latest&lt;</li>
      </ul>

      <table class="stats">
        <thead>
          <tr>
            <th class="rank">Rank</th>
            <th>Name</th>
            <th>Score</th>
          </tr>
        </thead>

        <tbody v-if="view == 'heroics'">
          <tr v-for="(hero, index) in heroics">
            <td class="rank">{{ index }}</td>
            <td><identity :name="hero.name"></identity></td>
            <td><spinner :score="hero.score" :spm="hero.spm"></spinner></td>
          </tr>
        </tbody>

        <tbody v-if="view == 'legendaries'">
          <tr v-for="(legend, index) in legendaries">
            <td class="rank">{{ index }}</td>
            <td><identity :name="legend.name"></identity></td>
            <td><spinner :score="legend.score" :spm="legend.spm"></spinner></td>
          </tr>
        </tbody>

        <tbody v-if="view == 'latest'">
          <tr v-for="(last, index) in latest">
            <td class="rank">{{ index }}</td>
            <td><identity :name="last.name"></identity></td>
            <td><spinner :score="last.score" :spm="last.spm"></spinner></td>
          </tr>
        </tbody>
      </table>
    </div>
  `
};