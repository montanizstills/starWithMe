package io.github.montanizstills;

import http.SimpleHttp;
import io.github.montanizstills.heygenAPI.HeygenEndpoints;
import io.github.montanizstills.heygenAPI.model.photo.*;

public class MainApplication {


    public static void main(String[] args) {
        PhotoSettings photo = PhotoSettings.builder()
                .name("Simple-Test-Photo")
                .age(Age.Unspecified)
                .gender(Gender.Man)
                .ethnicity(Ethnicity.White)
                .orientation(Orientation.Horizontal)
                .pose(Pose.Full_Body)
                .style(Style.Vintage)
                .appearance("dull colors; wool sweater; black dress shoes; bright lighting; standing in front of a window; clear sky background;")
                .build();

        String request = photo.toJson();
        System.out.println(request);
        SimpleHttp.POST.sendRequest(HeygenEndpoints.CREATE_PHOTO_AVATAR_PHOTOS, request);
    }
}