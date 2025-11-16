package io.github.montanizstills;

import http.SimpleHttp;
import io.github.montanizstills.heygenAPI.HeygenEndpoints;
import io.github.montanizstills.heygenAPI.model.*;
import io.github.montanizstills.heygenAPI.model.background.BackgroundSettings;
import io.github.montanizstills.heygenAPI.model.character.CharacterSettings;
import io.github.montanizstills.heygenAPI.model.character.CharacterSettingsType;
import io.github.montanizstills.heygenAPI.model.voice.VoiceSettings;
import io.github.montanizstills.heygenAPI.utils.Dimension;

import java.io.IOException;
import java.util.List;

public class MainApplication {

    public static void main(String[] args) throws IOException, InterruptedException {
        // Create voice settings
        VoiceSettings voiceSettings = VoiceSettings.builder()
                .voiceId("voice_id_123")
                .inputText("Hello, this is a test video!")
                .speed(1.0f)
                .pitch(0)
                .build();

        // Create avatar (character) settings
        CharacterSettings characterSettings = CharacterSettings.builder()
//                .type(String.valueOf(CharacterSettingsType.AVATAR)) // todo - should use default value but is omitted in JSON
                .avatarId("avatar_id_456")
                .scale(1.0f)
                .avatarStyle("normal")
                .build();

        // Create background settings
        BackgroundSettings backgroundSettings = BackgroundSettings.builder()
                .value("#FFFFFF")
                .build();

        // Wrap them in a VideoInput object
        VideoInput videoInput = VideoInput.builder()
                .character(characterSettings)
                .voice(voiceSettings)
                .background(backgroundSettings)
                .build();

        // Create dimension
        Dimension dimension = new Dimension(1280, 720);

        // Create the full request
        AvatarVideoRequest avatarVideoRequest = AvatarVideoRequest.builder()
                .videoInputs(List.of(videoInput))
                .dimension(dimension)
                .title("My Test Video from JavaAPI")
                .caption(Boolean.TRUE)
//                .callbackId("my-callback-id")
//                .folderId("my-folder-id")
//                .callbackUrl("https://example.com/callback")
                .build();

        // Convert to JSON
        String request = avatarVideoRequest.toJson();
        System.out.println(request);
//        SimpleHttp.POST.sendRequest(HeygenEndpoints.CREATE_VIDEO, request);
    }
}