package io.github.montanizstills.heygenAPI.model.background;

public enum PlayStyle {
    Freeze, Loop, Fit_To_Scene, Once;
    private String playStyle;

    PlayStyle() {
        this.playStyle = this.name().toLowerCase();
    }
}
