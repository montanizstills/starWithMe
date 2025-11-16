package io.github.montanizstills.heygenAPI.model.background;

public enum BackgroundType {
    Color, Image, Video;
    private String backgroundType;

    BackgroundType() {
        this.backgroundType = this.name().toLowerCase();
    }
}
