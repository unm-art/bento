require 'test_helper'

class SFXHandlerConcernTest < MiniTest::Test
  def test_eds_like_params_scan_url
    barcode = '39080014585712'
    call_number = 'PS3552.U827.P37 2000'
    collection = 'Stacks'
    library = 'Hayden Library'
    title = 'Parable of the sower'
    sfx_link = SFXHandler.new(
      barcode: barcode,
      call_number: call_number,
      collection: collection,
      library: library,
      title: title
    ).url_for_scan

    expected_url = 'https://sfx.mit.edu/sfx_test?sid=ALEPH:BENTO&amp;call_number=PS3552.U827.P37%202000&amp;barcode=39080014585712&amp;title=Parable%2520of%2520the%2520sower&amp;location=Hayden%2520Library&amp;genre=journal'

    assert_equal(expected_url, sfx_link)
  end

  def test_aleph_like_params_generic_url
    title = 'This is a title'
    clean_an = '35819515'
    sfx_link = SFXHandler.new(
      title: title,
      doc_number: clean_an,
    ).url_generic

    expected_url = 'https://sfx.mit.edu/sfx_test?sid=ALEPH:BENTO_FALLBACK&amp;call_number=&amp;barcode=&amp;title=This%20is%20a%20title&amp;location=&amp;pid=DocNumber=35819515,Ip=library.mit.edu,Port=9909'

    assert_equal(expected_url, sfx_link)
  end
end
