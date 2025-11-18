package io.github.montanizstills.heygenAPI.model.photo;

import io.github.montanizstills.heygenAPI.json.JsonEnum;

public enum Gender implements JsonEnum {
    Woman, Man, Unspecified;

    private final String gender;

    Gender() {
        this.gender = this.name(); // uses title-case capitalization
    }

    @Override
    public String getValue() {
        return this.gender;
    }
}
