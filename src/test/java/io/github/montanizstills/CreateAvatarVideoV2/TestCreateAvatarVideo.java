package io.github.montanizstills.CreateAvatarVideoV2;

import http.SimpleHttp;
import io.github.montanizstills.heygenAPI.HeygenEndpoints;
import io.github.montanizstills.heygenAPI.model.AvatarVideoRequest;
import io.github.montanizstills.heygenAPI.model.Dimension;
import io.github.montanizstills.heygenAPI.model.VideoInput;
import io.github.montanizstills.heygenAPI.model.background.BackgroundSettings;
import io.github.montanizstills.heygenAPI.model.background.BackgroundType;
import io.github.montanizstills.heygenAPI.model.character.AvatarStyle;
import io.github.montanizstills.heygenAPI.model.character.CharacterSettings;
import io.github.montanizstills.heygenAPI.model.voice.VoiceSettings;
import io.github.montanizstills.heygenAPI.model.voice.VoiceType;
import org.junit.jupiter.api.Test;

import java.util.List;

public class TestCreateAvatarVideo {
    @Test
    void CreateAvatarVideoV2() {
        // ======= Create avatar (character) settings =========
        CharacterSettings characterSettings = CharacterSettings.builder()
                .scale(1f)
                .avatarId("ef809a45b38340cf84cec36fa71c7aae") //todo - replace with lookup
                .avatarStyle(AvatarStyle.Normal)
                .build();

        // ======= Create voice settings =========
        VoiceSettings voiceSettings = VoiceSettings.builder()
                .type(VoiceType.Text)
                .voiceId("d3d194b2d2fd44298e4428b5f9358129") // todo - replace with lookup (run query for name return id)
                .inputText("Hello, this is a test video, my name is not Jay. I was written 20 seconds ago by awesome Nez, who just got off of work. Grand expectations are coming.!")
                .speed(1.0f)
                .pitch(0)
                .build();


        // ======= Create background settings =========
        BackgroundSettings backgroundSettings = BackgroundSettings.builder()
                .type(BackgroundType.Color)
                .value("#FFFFFF")
                .build();

        // Wrap them in a VideoInput object
        VideoInput videoInput = VideoInput.builder()
                .character(characterSettings)
                .voice(voiceSettings)
                .background(backgroundSettings)
                .build();


        // Create the full request
        AvatarVideoRequest avatarVideoRequest = AvatarVideoRequest.builder()
                .videoInputs(List.of(videoInput))
                .dimension(new Dimension(1280, 720))
                .title("My Second Test Video from JavaAPI")
                .caption(Boolean.TRUE)
//                .callbackId("my-callback-id")
//                .folderId("my-folder-id")
//                .callbackUrl("https://example.com/callback")
                .build();

        // Convert to JSON
        String request = avatarVideoRequest.toJson();
        System.out.println(request);
        SimpleHttp.POST.sendRequest(HeygenEndpoints.CREATE_AVATAR_VIDEO_V2, request);

    }
}
