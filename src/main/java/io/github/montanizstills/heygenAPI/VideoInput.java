package io.github.montanizstills.heygenAPI;

import org.springframework.boot.configurationprocessor.json.JSONObject;

public enum VideoInput {

    test();

    private CharacterObject character;
    private VoiceObject voice;
    private BackgroundObject background;
    private TextObject textObject;
    private JSONObject body;

    VideoInput(JSONObject jsonObject) {
        this.body = jsonObject;
    }
}
