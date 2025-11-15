package io.github.montanizstills.heygenAPI.model;

import java.util.List;

// ==================== Usage Example ====================
class HeyGenAPIExample {
    public static void main(String[] args) {
        // Create a simple avatar video request
        TextVoiceSettings voice = new TextVoiceSettings("voice_id_123", "Hello, this is a test video!");
        AvatarSettings avatar = new AvatarSettings("avatar_id_456");
        ColorBackground background = new ColorBackground("#ffffff");

        io.github.montanizstills.heygenAPI.VideoInput videoInput = new io.github.montanizstills.heygenAPI.VideoInput(avatar, voice, background);
        Dimension dimension = new Dimension(1920, 1080);

        CreateAvatarVideoRequest request = new CreateAvatarVideoRequest(
                List.of(videoInput),
                dimension
        );
        request.setTitle("My Test Video");
        request.setCaption(true);

        // Convert to JSON
        System.out.println(request.toString());
    }
}
