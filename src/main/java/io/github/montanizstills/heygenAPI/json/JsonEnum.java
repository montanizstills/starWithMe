package io.github.montanizstills.heygenAPI.json;

import com.fasterxml.jackson.annotation.JsonValue;
import com.fasterxml.jackson.databind.annotation.JsonDeserialize;

/**
 * Interface for enums that need to serialize to JSON with custom string values.
 * <p>
 * Implementing enums ONLY need to provide getValue() method.
 * Both serialization and deserialization are handled automatically!
 */
@JsonDeserialize(using = JsonEnumDeserializer.class)
public interface JsonEnum {

    /**
     * Returns the JSON string representation of this enum value.
     * This is the ONLY method that implementing enums must provide.
     */
    String getValue();

    /**
     * Default implementation for JSON serialization.
     * The @JsonValue annotation ensures Jackson uses this for serialization.
     */
    @JsonValue
    default String toJson() {
        return getValue();
    }

    /**
     * Helper method to find an enum value by its string representation.
     * Used internally by the deserializer.
     * <p>
     * This version accepts any Enum class that implements JsonEnum,
     * making it easier to call from the deserializer without complex casts.
     */
    @SuppressWarnings("unchecked")
    static <E extends Enum<E> & JsonEnum> E fromValue(Class<?> enumClass, String value) {
        if (!enumClass.isEnum()) {
            throw new IllegalArgumentException(enumClass.getName() + " is not an enum type");
        }

        if (!JsonEnum.class.isAssignableFrom(enumClass)) {
            throw new IllegalArgumentException(enumClass.getName() + " does not implement JsonEnum");
        }

        if (value == null) {
            throw new IllegalArgumentException(enumClass.getSimpleName() + " value cannot be null");
        }

        // Safe cast because we verified above
        Class<E> enumType = (Class<E>) enumClass;

        for (E enumConstant : enumType.getEnumConstants()) {
            if (enumConstant.getValue().equalsIgnoreCase(value)) {
                return enumConstant;
            }
        }

        throw new IllegalArgumentException("Unknown " + enumClass.getSimpleName() + " value: '" + value + "'. " + "Valid values are: " + getValidValues(enumType));
    }

    /**
     * Helper method to get a comma-separated list of valid values for error messages.
     */
    static <E extends Enum<E> & JsonEnum> String getValidValues(Class<E> enumClass) {
        StringBuilder sb = new StringBuilder();
        E[] constants = enumClass.getEnumConstants();
        for (int i = 0; i < constants.length; i++) {
            sb.append("'").append(constants[i].getValue()).append("'");
            if (i < constants.length - 1) {
                sb.append(", ");
            }
        }
        return sb.toString();
    }
}