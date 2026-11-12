import assert from "node:assert/strict";
import test from "node:test";
import {
  validateCommunityPost,
  validateCommunityReport,
  validateModeration,
  communityRemovePostId,
  communityFeedCursor,
  adminAnnouncementId,
} from "../supabase/functions/member-api-v26/community_validation";

const id = "bc8e3ef2-a487-46da-b3d1-d0747607a4bc";
const other = "45dca33e-4a7e-48c3-9c1e-56e014f74440";

test("B4 sports posts reject private contact information and spam links", () => {
  const valid = validateCommunityPost({
    topic: "running", content: "  Mi primer 10K salió muy bien.  ",
    user_id: "forged", status: "visible",
  });
  assert.deepEqual(valid, {
    p_topic: "running", p_content: "Mi primer 10K salió muy bien.",
  });
  assert.equal(validateCommunityPost({topic:"running",content:"short"}),null);
  assert.equal(validateCommunityPost({topic:"hacking",content:"Caminata el domingo en grupo"}),null);
  assert.equal(validateCommunityPost({topic:"running",content:"Mi número es 5512345678 para entrenar"}),null);
  assert.equal(validateCommunityPost({topic:"running",content:"Escríbeme a x@y.com para correr"}),null);
  assert.equal(validateCommunityPost({topic:"running",content:"Visita https://example.com mañana"}),null);
  assert.equal(validateCommunityPost({topic:"running",content:"a".repeat(481)}),null);
});

test("B4 report accepts exactly one target and bounded private explanation", () => {
  assert.deepEqual(validateCommunityReport({
    post_id:id,reason:"unsafe",detail:"  Actividad peligrosa ",
  }),{
    p_post_id:id,p_user_id:null,p_reason:"unsafe",p_detail:"Actividad peligrosa",
  });
  assert.equal(validateCommunityReport({
    post_id:id,user_id:other,reason:"unsafe",
  }),null);
  assert.equal(validateCommunityReport({reason:"spam"}),null);
  assert.equal(validateCommunityReport({post_id:id,reason:"fake"}),null);
  assert.equal(validateCommunityReport({user_id:other,reason:"privacy",detail:"a".repeat(301)}),null);
  assert.equal(validateCommunityReport({user_id:"not-id",reason:"privacy"}),null);
});

test("B4 moderation enforces report UUID, human notes and action allowlist", () => {
  assert.deepEqual(validateModeration({
    report_id:id,action:"hide_post",note:"  Contenido expone privacidad. ",
  }),{
    p_report_id:id,p_action:"hide_post",p_note:"Contenido expone privacidad.",
  });
  assert.equal(validateModeration({
    report_id:id,action:"delete_user",note:"Acción peligrosa",
  }),null);
  assert.equal(validateModeration({
    report_id:id,action:"dismiss",note:"ok",
  }),null);
});

test("B4 strict routes reject path tricks and invalid cursor", () => {
  assert.equal(communityRemovePostId("/v1/community/posts/"+id),id);
  assert.equal(communityRemovePostId("/v1/community/posts/"+id+"/details"),null);
  assert.equal(communityRemovePostId("/v1/community/posts/not-a-uuid"),null);
  assert.equal(adminAnnouncementId("/v1/admin/community/announcements/"+id),id);
  assert.equal(adminAnnouncementId("/v1/admin/community/announcements/"+id+"/extra"),null);
  assert.equal(communityFeedCursor(null),null);
  assert.equal(communityFeedCursor("2026-11-12T20:10:11.123Z"),"2026-11-12T20:10:11.123Z");
  assert.equal(communityFeedCursor("2026-11-12T20:10:11.123Z?x=1"),false);
  assert.equal(communityFeedCursor("../../etc/passwd"),false);
});
