package io.github.montanizstills.heygenAPI.model.text;

public enum TextAlign {
    LEFT,
    CENTER,
    RIGHT;

    private String textAlign;

    TextAlign() {
        this.textAlign = this.name().toLowerCase();
    }
}
