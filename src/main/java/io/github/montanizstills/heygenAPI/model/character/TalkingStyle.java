package io.github.montanizstills.heygenAPI.model.character;

public enum TalkingStyle {
    Stable, Expressive;

    private final String talkingStyle;

    TalkingStyle() {
        this.talkingStyle = this.name().toLowerCase();
    }
}
