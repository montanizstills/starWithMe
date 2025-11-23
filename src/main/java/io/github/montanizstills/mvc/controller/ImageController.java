package io.github.montanizstills.mvc.controller;

import io.github.montanizstills.heygenAPI.HeygenEndpoints;
import io.github.montanizstills.mvc.model.ImageGenerationDTO;
import io.github.montanizstills.mvc.service.ImageDTOService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequiredArgsConstructor
public class ImageController {
    @RequestMapping(path = HeygenEndpoints.DELETE_VIDEO, method = RequestMethod.POST)
    public ResponseEntity<String> deleteVideo(@RequestParam String asset_id) {
//        HttpClient client = HttpClient.newHttpClient();
//        HttpRequest request = HttpRequest.newBuilder()
//                .uri(URI.create(HeygenEndpoints.USER_DATA.getURL()))
//                .POST(HttpRequest.BodyPublishers.ofString("body"))
//                .build();
        return new ResponseEntity<>("", HttpStatus.OK);
    }

    @RequestMapping(path = "/create-image", method = RequestMethod.POST)
    public ResponseEntity<ImageGenerationDTO> createAImage() {
        ImageGenerationDTO imageGenerationDTO = this.imageDTOService.createImage();
        return new ResponseEntity<>(imageGenerationDTO, HttpStatus.OK);
    }


    private final ImageDTOService imageDTOService;

//    @Autowired //removed Spring4.3, only one constructor
//    public ImageController(ImageDTOService imageDTOService) {
//        this.imageDTOService = imageDTOService;
//    }
}