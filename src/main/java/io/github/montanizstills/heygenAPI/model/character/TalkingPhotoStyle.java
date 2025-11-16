package io.github.montanizstills.heygenAPI.model.character;

public enum TalkingPhotoStyle {
    Circle, Square;

    private String talkingPhotoStyle;

    TalkingPhotoStyle() {
        this.talkingPhotoStyle = this.name().toLowerCase();
    }
}
