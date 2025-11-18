package io.github.montanizstills.heygenAPI.model.photo;

import io.github.montanizstills.heygenAPI.json.JsonEnum;

public enum Ethnicity implements JsonEnum {
    White, Black, Asian_American, East_Asian, South_East_Asian, South_Asian, Middle_Eastern, Pacific, Hispanic, Unspecified;
    private final String ethnicity;

    Ethnicity() {
        this.ethnicity = this.name().toLowerCase();
    }


    @Override
    public String getValue() {
        return this.ethnicity;
    }
}
