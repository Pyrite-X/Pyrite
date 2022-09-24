import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:alfred/alfred.dart';
import 'package:cryptography/cryptography.dart';
import 'package:onyx/onyx.dart';

class WebServer {
  Alfred server;
  String PUB_KEY;

  WebServer(this.server, this.PUB_KEY);

  Future<void> startServer({required Function(Interaction) dispatchFunc, int port = 8080}) async {
    server.get("/", (req, res) => "Thanks for visiting root!");

    server.get("/ws", (req, res) => "Oi, this is for webhooks ONLY");

    server.post("/ws", (req, res) async {
      Map<String, dynamic> body = await req.body as Map<String, dynamic>;

      if (body["type"] == 1) {
        /// Ping, Pong!
        return {"type": 1};
      } else {
        Interaction interaction = Interaction(body);
        interaction.setMetadata(req);

        dispatchFunc(interaction);
      }
    }, middleware: [_validateDiscordWebhook]);

    await server.listen(port);
  }

  /// Middleware logic to validate that the incoming webhooks are from Discord.
  FutureOr _validateDiscordWebhook(HttpRequest req, HttpResponse res) async {
    final String signature = req.headers.value("X-Signature-Ed25519")!;
    final String timestamp = req.headers.value("X-Signature-Timestamp")!;

    var bodyObj = await req.body;
    final String bodyString = jsonEncode(bodyObj);

    final algorithm = Ed25519();

    PublicKey pubkey = SimplePublicKey(_nHexToBytes(PUB_KEY), type: KeyPairType.ed25519);
    Signature signatureObj = Signature(_nHexToBytes(signature), publicKey: pubkey);

    bool result = await algorithm.verify(utf8.encode("$timestamp$bodyString"), signature: signatureObj);
    if (!result) {
      throw AlfredException(401, "Invalid request signature.");
    }
  }

  /// Converts a Hex string of n length into a Uint8List (byte representation).
  Uint8List _nHexToBytes(String hex) {
    List<int> resultList = [];

    for (int i = 0; i < hex.length; i += 2) {
      resultList.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }

    return Uint8List.fromList(resultList);
  }
}
