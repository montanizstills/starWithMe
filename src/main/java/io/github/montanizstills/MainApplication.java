package io.github.montanizstills;

import io.github.montanizstills.heygenAPI.model.*;

import java.util.List;

public class MainApplication {

    public static void main(String[] args) {
        // Create voice settings
        TextVoiceSettings voice = TextVoiceSettings.builder()
                .voiceId("voice_id_123")
                .inputText("Hello, this is a test video!")
                .speed(1.0f)
                .pitch(0)
                .build();

        // Create avatar (character) settings
        AvatarSettings avatar = AvatarSettings.builder()
                .avatarId("avatar_id_456")
                .scale(1.0f)
                .avatarStyle("normal")
                .build();

        // Create background settings
        ColorBackground background = ColorBackground.builder()
                .value("#FFFFFF")
                .build();

        // Wrap them in a VideoInput object
        VideoInput videoInput = VideoInput.builder()
                .character(avatar)
                .voice(voice)
                .background(background)
                .build();

        // Create dimension
        Dimension dimension = new Dimension(1280, 720);

        // Create the full request
        AvatarVideoRequest avatarVideoRequest = AvatarVideoRequest.builder()
                .title("My Test Video from JavaAPI")
                .caption(Boolean.TRUE)
                .videoInputs(List.of(videoInput))
                .dimension(dimension)
//                .callbackId("my-callback-id")
//                .folderId("my-folder-id")
//                .callbackUrl("https://example.com/callback")
                .build();

        // Convert to JSON
        System.out.println(avatarVideoRequest.toJson());
    }
}