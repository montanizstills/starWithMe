package io.github.montanizstills.heygenAPI.model.voice;

public enum Emotion {
    Excited, Friendly, Serious, Soothing, Broadcaster;

    private String emotion;

    Emotion(){
        this.emotion = this.name().toLowerCase();
    }
}
