package io.github.montanizstills.heygenAPI.model.photo;

import io.github.montanizstills.heygenAPI.json.JsonEnum;

public enum Orientation implements JsonEnum {
    Square, Horizontal, Vertical;

    private final String orientation;

    Orientation(){
        this.orientation = this.name().toLowerCase();
    }
    @Override
    public String getValue() {
        return this.orientation;
    }
}
