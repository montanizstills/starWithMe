package io.github.montanizstills;

import io.github.montanizstills.heygenAPI.VideoInput;
import io.github.montanizstills.heygenAPI.model.*;

import java.util.List;


public class MainApplication {

    public static void main(String[] args) {
        //        SpringApplication.run(MainApplication.class, args);
//        HeygenUtils heygenUtils = new HeygenUtils();
//        heygenUtils.createAPIKey();

        // Create a simple avatar video avatarVideoRequest
        TextVoiceSettings voice = TextVoiceSettings.builder()
                .voiceId("voice_id_123")
                .inputText("Hello, this is a test video!")
                .build();
        AvatarSettings avatar = AvatarSettings.builder()
                .avatarId("avatar_id_456")
                .build();

        ColorBackground background = new ColorBackground("#ffffff");

        VideoInput videoInput = new VideoInput(List.of(voice, avatar, background));
        Dimension dimension = new Dimension(1920, 1080);

        AvatarVideoRequest avatarVideoRequest = new AvatarVideoRequest(
                List.of(videoInput),
                dimension
        );
        avatarVideoRequest.setTitle("My Test Video");
        avatarVideoRequest.setCaption(true);

        // Convert to JSON
        System.out.println(avatarVideoRequest.toJson());
    }

}
