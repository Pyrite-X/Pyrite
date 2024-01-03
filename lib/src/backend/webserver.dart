import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:alfred/alfred.dart';
import 'package:cryptography/cryptography.dart';
import 'package:onyx/onyx.dart';

class WebServer {
  Alfred server;
  String PUB_KEY;

  WebServer(this.server, this.PUB_KEY);

  Future<void> startServer(
      {required Future<dynamic> Function(Interaction) dispatchFunc,
      int port = 8080,
      SecurityContext? securityContext}) async {
    server.get("/ws", (req, res) => "You're not supposed to \"GET\" this endpoint... But it's working!");

    server.post("/ws", (req, res) async {
      Map<String, dynamic> body = await req.body as Map<String, dynamic>;
      req.response.headers.contentType = ContentType.json;

      if (body["type"] == 1) {
        return InteractionResponse(InteractionResponseType.pong, {});
      } else {
        Interaction interaction = Interaction(body);
        interaction.setMetadata(req);

        await dispatchFunc(interaction);
      }
    }, middleware: [_validateDiscordWebhook]);

    if (securityContext != null) {
      await server.listenSecure(securityContext: securityContext, port: port);
    } else {
      await server.listen(port);
    }
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
