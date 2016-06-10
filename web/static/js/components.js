import Vue from 'vue'

const spinRate = 16 // milliseconds

let spinner = Vue.component('spinner', {
	data: function() {
		return {
			interval: null
		};
	},
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
	template: `<span class="score">{{ prettyScore }}</span>&gt;<span class="spm">{{ prettySPM }}</span>`
});

let identity = Vue.component('identity', {
	data: function(){
		return {
			name: '',
			troupe: ''
		}
	},
	props: ['name', 'troupe'],
	computed: {
		identity: {
			get: function(){
				let s = '';
				if (this.name){
					s += '@'+this.name;
				}
				if (this.troupe){
					s += '#'+this.troupe;
				}
				return s;
			}
		}
	},
	template: `<span class="identity">{{ identity }}</span>`
});

let message = Vue.component('message', {
	data: function(){
		return {
			body: '',
			time: '',
			name: '',
			troupe: '',
		}
	},
	props: ['message'],
	template: `
<div class="message"
	v-bind:class="{
		'same-team': same_team,
		'admin': is_admin}
	">
	<div class="message_header">
		<span class="timestamp">12:34</span>
		<identity :name="name"
			:troupe="troupe"></identity>
	</div>
	<div class="message_body">{{ body }}</div>
</div>
	`
});

let chatRoom = Vue.component('chat-room', {
	data: function() {
		return {
			messages: [],
			input: ''
		}
	},
	props: ['channel'],
	template: `
<div class="messages fill">
	<message v-for="message in messages"
		:message="message"></message>
</div>`
});

let scoreboard = Vue.component('scoreboard', {
	data: function() {
		return { view: 'heroics' }
	},
	props: {
		scoreboard: {
			required: true,
			default: function() {
				return {};
			}
		}
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
		<tr v-for="hero in heroics">
			<td class="rank">{{ $index }}</td>
			<td><identity :name="hero.name"></identity></td>
			<td><spinner :score="hero.score" :spm="hero.spm"></spinner></td>
		</tr>
	</tbody>

	<tbody v-if="view == 'legendaries'">
		<tr v-for="legend in legendaries">
			<td class="rank">{{ $index }}</td>
			<td><identity :name="legend.name"></identity></td>
			<td><spinner :score="legend.score" :spm="legend.spm"></spinner></td>
		</tr>
	</tbody>

	<tbody v-if="view == 'latest'">
		<tr v-for="last in latest">
			<td class="rank">{{ $index }}</td>
			<td><identity :name="last.name"></identity></td>
			<td><spinner :score="last.score" :spm="last.spm"></spinner></td>
		</tr>
	</tbody>
</table>`
});
