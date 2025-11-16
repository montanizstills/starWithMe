package io.github.montanizstills;

import io.github.montanizstills.heygenAPI.model.AvatarVideoRequest;
import io.github.montanizstills.heygenAPI.model.VideoInput;
import io.github.montanizstills.heygenAPI.model.background.BackgroundSettings;
import io.github.montanizstills.heygenAPI.model.character.AvatarStyle;
import io.github.montanizstills.heygenAPI.model.character.CharacterSettings;
import io.github.montanizstills.heygenAPI.model.voice.VoiceSettings;
import io.github.montanizstills.heygenAPI.model.voice.VoiceType;
import io.github.montanizstills.heygenAPI.model.Dimension;

import java.util.List;

public class MainApplication {

    public static void main(String[] args) {
        // ======= Create avatar (character) settings =========
        CharacterSettings characterSettings = CharacterSettings.builder()
                .scale(1f)
                .avatarId("Test-Avatar01")
                .avatarStyle(AvatarStyle.Normal)
                .build();

        // ======= Create voice settings =========
        VoiceSettings voiceSettings = VoiceSettings.builder()
                .type(VoiceType.Text)
                .voiceId("voice_id_123")
                .inputText("Hello, this is a test video!")
                .speed(1.0f)
                .pitch(0)
                .build();


        // ======= Create background settings =========
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