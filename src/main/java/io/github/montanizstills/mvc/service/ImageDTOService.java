package io.github.montanizstills.mvc.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.github.montanizstills.heygenAPI.HeygenEndpoints;
import io.github.montanizstills.heygenAPI.model.photo.*;
import io.github.montanizstills.http.SimpleHttp;
import io.github.montanizstills.http.SimpleHttpResponse;
import io.github.montanizstills.mvc.model.ImageGenerationDTO;
import io.github.montanizstills.mvc.repository.ImageDTORepository;
import io.github.montanizstills.utils.Utils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.Map;

@Service
public class ImageDTOService {
    private final ImageDTORepository imageDTORepository;

    @Autowired
    public ImageDTOService(ImageDTORepository imageDTORepository) {
        this.imageDTORepository = imageDTORepository;
    }

    public ImageGenerationDTO createImage() {
        SimpleHttpResponse response = SimpleHttp.POST.sendRequest(
                HeygenEndpoints.CREATE_PHOTO_AVATAR_PHOTOS,
                PhotoSettings.builder()
                        .name("Simple-Test-Photo_Java_API")
                        .age(Age.Senior)
                        .gender(Gender.Woman)
                        .ethnicity(Ethnicity.Hispanic)
                        .orientation(Orientation.Vertical)
                        .pose(Pose.Half_Body)
                        .style(Style.CyberPunk)
                        .appearance("dull colors; wool sweater; red dress shoes; bright lighting; standing in front of a window; clear sky background;")
                        .build()
                        .toJson()
        );
        System.out.println("\nResponse Body: " + response.getBody()+"\n");
        JsonNode root = null;
        try {
            root = new ObjectMapper().readTree(response.getBody());
        } catch (JsonProcessingException e) {
            throw new RuntimeException(e);
        }
        System.out.println(root.get("data").get("generation_id"));


        ImageGenerationDTO imageDTO = ImageGenerationDTO.builder()
                .generationID(root.get("data").get("generation_id").toString())
                .build();
        return this.imageDTORepository.save(imageDTO);
    }
}
