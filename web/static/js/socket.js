// NOTE: The contents of this file will only be executed if
// you uncomment its entry in "web/static/js/app.js".

// To use Phoenix channels, the first step is to import Socket
// and connect at the socket path in "lib/my_app/endpoint.ex":
import {Socket} from "phoenix"

let socket = new Socket("/socket", {params: {token: window.userToken}})

// When you connect, you'll often need to authenticate the client.
// For example, imagine you have an authentication plug, `MyAuth`,
// which authenticates the session and assigns a `:current_user`.
// If the current user exists you can assign the user's token in
// the connection for use in the layout.
//
// In your "web/router.ex":
//
//     pipeline :browser do
//       ...
//       plug MyAuth
//       plug :put_user_token
//     end
//
//     defp put_user_token(conn, _) do
//       if current_user = conn.assigns[:current_user] do
//         token = Phoenix.Token.sign(conn, "user socket", current_user.id)
//         assign(conn, :user_token, token)
//       else
//         conn
//       end
//     end
//
// Now you need to pass this token to JavaScript. You can do so
// inside a script tag in "web/templates/layout/app.html.eex":
//
//     <script>window.userToken = "<%= assigns[:user_token] %>";</script>
//
// You will need to verify the user token in the "connect/2" function
// in "web/channels/user_socket.ex":
//
//     def connect(%{"token" => token}, socket) do
//       # max_age: 1209600 is equivalent to two weeks in seconds
//       case Phoenix.Token.verify(socket, "user socket", token, max_age: 1209600) do
//         {:ok, user_id} ->
//           {:ok, assign(socket, :user, user_id)}
//         {:error, reason} ->
//           :error
//       end
//     end
//
// Finally, pass the token on connect as below. Or remove it
// from connect if you don't care about authentication.

socket.connect()

import Vue from 'vue'

/**
 * Shouting
 */
/**
 * Squad
 */
let squadChannel;
let squadForm = $("form[name=squad]")
let squadName = $(".name", squadForm)
var squadScoreField = $('.squad-score')

let join = $(".join", squadForm)
let joining = () => {
  if (squadChannel) {
    squadChannel.leave()
  }
  squadChannel = socket.channel("arenas:squads:" + squadName.val())

  squadChannel.join().receive("ok", resp => {
    console.log("Joined squads", resp)
  })
  squadChannel.on("introspect", (resp) => {
    console.log(resp)
    squadSpin(resp)
  })
}

join.click(joining)
squadName.on("keypress", event => {
  if (event.keyCode === 13) {
    joining()
    event.preventDefault()
    return false
  }
});

let setSquadScore = (score) => {
  squadScoreField.html(score.toFixed(3))
}

let squadInterval
let squadSpin = (stat) => {
  if (squadInterval) {
    clearInterval(squadInterval);
  }

  setSquadScore(stat.score)

  let localSpin = ((stat.spm / 60) * (spinRate / 1000))
  squadInterval = setInterval(() => {
    stat.score = stat.score + localSpin
    setSquadScore(stat.score)
  }, spinRate)
}

export default socket;
