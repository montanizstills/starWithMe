package io.github.montanizstills.heygenAPI.model.background;

public enum Fit {
    Crop, Cover, Contain, None;
    private String fit;

    Fit() {
        this.fit = this.name().toLowerCase();
    }
}
