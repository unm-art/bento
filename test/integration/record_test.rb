require 'test_helper'

class RecordTest < ActionDispatch::IntegrationTest
  test 'article title is shown' do
    VCR.use_cassette('record: article', allow_playback_repeats: true) do
      get record_url, params: { db_source: 'aci', an: '123877356' }
      assert_response :success
      assert_select('h2') do |value|
        assert(value.text.include?('Ultrasensitive Label-Free Sensing of IL-6'))
      end
    end
  end

  test 'book title is shown' do
    VCR.use_cassette('record: book', allow_playback_repeats: true) do
      get record_url, params: { db_source: 'cat00916a', an: 'mit.001492509' }
      assert_response :success
      assert_select('h2') do |value|
        assert(value.text.include?('Bananas : how the United Fruit Company'))
      end
    end
  end

  test 'journal title is shown' do
    VCR.use_cassette('record: journal', allow_playback_repeats: true) do
      get record_url, params: { db_source: 'cat00916a', an: 'mit.000292123' }
      assert_response :success
      assert_select('h2') do |value|
        assert(value.text.include?('Blood.'))
      end
    end
  end

  test 'back to search results link is shown where available' do
    VCR.use_cassette('record: book', allow_playback_repeats: true) do
      get record_url, params: { db_source: 'cat00916a',
                                an: 'mit.001492509',
                                previous: 'bananas' }
      assert_response :success
      assert_select('a[href=?]', search_bento_path(q: 'bananas')) do |value|
        assert(value.text.include?('Back to search results'))
      end
    end
  end

  test 'back to search results link not shown where unavailable' do
    VCR.use_cassette('record: book', allow_playback_repeats: true) do
      get record_url, params:
                        { db_source: 'cat00916a',
                          an: 'mit.001492509' } # note: no 'previous' param
      assert_response :success
      assert response.body.exclude? 'Back to search results'
    end
  end

  test 'course reserve material is viewable' do
    VCR.use_cassette('record: course reserve', allow_playback_repeats: true) do
      get record_url, params: { db_source: 'cat01763a', an: 'mitcr.000115377' }
      assert_response :success
      assert_select('h2') do |value|
        assert(value.text.include?('Inorganic chemistry'))
      end
    end
  end

  test 'view online button is shown' do
    VCR.use_cassette('record: view online', allow_playback_repeats: true) do
      get record_url, params: { db_source: 'ibh', an: '124089570' }
      assert_select 'a.button-primary', text: 'View online'
      assert_select 'a', text: 'Check for online copy', count: 0
    end
  end

  test 'sign in for access button is shown' do
    VCR.use_cassette('record: article', allow_playback_repeats: true) do
      get record_url, params: { db_source: 'aci', an: '123877356' }
      assert_select 'a.button-secondary', text: 'Sign in for access'
      assert_select 'a', text: 'Check for online copy', count: 0
    end
  end

  test 'check for online copy link shown when SFX URL is not fulltext' do
    VCR.use_cassette('record: not fulltext', allow_playback_repeats: true) do
      get record_url, params: { db_source: 'edselp', an: 'S002965541630392X' }
      assert_response :success
      assert_select 'a.button-primary', text: 'View online', count: 0
      assert_select 'a', text: 'Check for online copy'
    end
  end

  test 'check for view online button shown when SFX URL is fulltext' do
    VCR.use_cassette('record: sfx fulltext', allow_playback_repeats: true) do
      get record_url, params: { db_source: 'lxh', an: '102229662' }
      assert_response :success
      assert_select 'a.button-primary', text: 'View online'
      assert_select 'a', text: 'Check for online copy', count: 0
    end
  end

  test 'emergency backup SFX link shown when we do not know what to do' do
    # NOTE: this record is no longer in EDS but it is not clear how to indentify
    # a suitable replacement record at this time. The cassette has been
    # manually manipulated and can't be easily regenerated.
    VCR.use_cassette('record: omgwtfbbq', allow_playback_repeats: true) do
      get record_url, params: { db_source: 'edsasp', an: 'edsasp.ASP2223378.CLMU' }
      assert_response :success
      assert_select 'a.button-primary', text: 'View online', count: 0
      assert_select 'a', text: 'Check for online copy'
    end
  end

  test 'summary holdings are shown when available' do
    VCR.use_cassette('record: journal', allow_playback_repeats: true) do
      get record_url, params: { db_source: 'cat00916a', an: 'mit.000292123' }
      assert_select 'div#full-holdings'
      assert @response.body.include? 'v.1 (1946)- v.115:p.1315-2560 (2010)'
    end
  end

  test 'summary holdings are not shown when not available' do
    VCR.use_cassette('record: article', allow_playback_repeats: true) do
      get record_url, params: { db_source: 'aci', an: '123877356' }
      assert_select('div#full-holdings', false)
    end
  end

  test 'scan button not shown for engineering standards' do
    VCR.use_cassette('record: engineering standard', allow_playback_repeats: true) do
      get record_url, params: { db_source: 'cat00916a', an: 'mit.001480933' }
      assert @response.body.exclude? 'Request scan (2-3 days)'
    end
  end

  test 'bogus item not shown when record items exceed 990' do
    VCR.use_cassette('record: egregiously many items', allow_playback_repeats: true) do
      get record_url, params: { db_source: 'cat00916a', an: 'mit.000296523' }
      assert_select 'span.library', text: '', count: 0
      assert_select 'span.collection', text: ':', count: 0
      assert_select 'span.callno', text: '', count: 0
    end
  end

  test 'multiple item types can be shown' do
    VCR.use_cassette('record: multiple item types', allow_playback_repeats: true) do
      get record_url, params: { db_source: 'cat00916a', an: 'mit.002379994' }
      assert_select 'span.record-type', text: /Book; eBook/
    end
  end

  # ~~~~~~~~~~~~~~~~~~~ tests of 'more information' section ~~~~~~~~~~~~~~~~~~~
  # For the following tests, note that not all information is available for all
  # sources.
  test 'document type is shown' do
    VCR.use_cassette('record: article', allow_playback_repeats: true) do
      get record_url, params: { db_source: 'aci', an: '123877356' }
      assert_response :success
      assert @response.body.include? '<span class="label">Document type:</span> Academic Journal'
    end
  end

  test 'source is shown' do
    VCR.use_cassette('record: article', allow_playback_repeats: true) do
      get record_url, params: { db_source: 'aci', an: '123877356' }
      assert_response :success
      assert @response.body.include? '<span class="label">Source:</span> Biosensors (2079-6374)'
    end
  end

  test 'authors are shown' do
    VCR.use_cassette('record: article', allow_playback_repeats: true) do
      get record_url, params: { db_source: 'aci', an: '123877356' }
      assert_response :success
      assert @response.body.include? 'Khosravi, Farhad'
      assert @response.body.include? 'Loeian, Seyed Masoud'
      assert @response.body.include? 'Panchapakesan, Balaji'
    end
  end

  test 'author affiliations are shown' do
    VCR.use_cassette('record: article', allow_playback_repeats: true) do
      get record_url, params: { db_source: 'aci', an: '123877356' }
      assert_response :success
      assert @response.body.include? 'Small Systems Laboratory, Department of Mechanical Engineering, Worcester Polytechnic Institute, Worcester, MA 01532, USA'
    end
  end

  test 'publication info is shown' do
    VCR.use_cassette('record: book', allow_playback_repeats: true) do
      get record_url, params: { db_source: 'cat00916a', an: 'mit.001492509' }
      assert_response :success
      assert @response.body.include? '<span class="label">Publication info:</span> Edinburgh ; New York : Canongate ; [Berkeley, Calif.?] : Distributed by Publishers Group West, c2007.'
    end
  end

  test 'issn is shown' do
    VCR.use_cassette('record: article', allow_playback_repeats: true) do
      get record_url, params: { db_source: 'aci', an: '123877356' }
      assert_response :success
      assert @response.body.include? '<span class="label">ISSN:</span>'
      assert @response.body.include? '<span class="isbn">20796374</span>'
    end
  end

  test 'isbn is shown' do
    VCR.use_cassette('record: book', allow_playback_repeats: true) do
      get record_url, params: { db_source: 'cat00916a', an: 'mit.001492509' }
      assert_response :success
      assert @response.body.include? '<span class="label">ISBN:</span>'
      assert @response.body.include? '<span class="isbn">9781841958811</span>'
    end
  end

  test 'doi is shown' do
    VCR.use_cassette('record: article', allow_playback_repeats: true) do
      get record_url, params: { db_source: 'aci', an: '123877356' }
      assert_response :success
      assert @response.body.include? '<span class="label">DOI:</span> 10.3390/bios7020017'
    end
  end

  test 'language is shown' do
    VCR.use_cassette('record: article', allow_playback_repeats: true) do
      get record_url, params: { db_source: 'aci', an: '123877356' }
      assert_response :success
      assert @response.body.gsub(/\s+/, " ").include? '<span class="label">Language:</span> English'
    end
  end

  test 'physical description is shown' do
    VCR.use_cassette('record: book', allow_playback_repeats: true) do
      get record_url, params: { db_source: 'cat00916a', an: 'mit.001492509' }
      assert_response :success
      assert @response.body.include? '<span class="label">Physical description:</span> xv, 224 p. : map ; 21 cm.'
    end
  end

  test 'database is shown' do
    VCR.use_cassette('record: book', allow_playback_repeats: true) do
      get record_url, params: { db_source: 'cat00916a', an: 'mit.001492509' }
      assert_response :success
      assert @response.body.include? '<span class="label">Database:</span> MIT Barton Catalog'
    end
  end

  test 'subjects are shown' do
    VCR.use_cassette('record: article', allow_playback_repeats: true) do
      get record_url, params: { db_source: 'aci', an: '123877356' }
      assert_response :success
      assert @response.body.include? 'Carbon nanotubes'
      assert @response.body.include? 'Biosensors'
      assert @response.body.include? 'Molecular recognition'
    end
  end

  test 'keywords are shown' do
    VCR.use_cassette('record: article', allow_playback_repeats: true) do
      get record_url, params: { db_source: 'aci', an: '123877356' }
      assert_response :success
      assert @response.body.include? 'Carbon Nanotube Biosensors'
      assert @response.body.include? 'Field Effect Transistors'
      assert @response.body.include? 'IL6'
    end
  end

  test 'abstract is shown' do
    VCR.use_cassette('record: article', allow_playback_repeats: true) do
      get record_url, params: { db_source: 'aci', an: '123877356' }
      assert_response :success
      assert @response.body.include? 'This study demonstrates the rapid and label-free detection of Interleukin-6'
    end
  end

  test 'notes are shown' do
    VCR.use_cassette('record: book', allow_playback_repeats: true) do
      get record_url, params: { db_source: 'cat00916a', an: 'mit.001492509' }
      assert_response :success
      assert @response.body.include? 'Originally published as: Jungle capitalists.'
    end
  end

  test 'other titles are shown' do
    VCR.use_cassette('record: book', allow_playback_repeats: true) do
      get record_url, params: { db_source: 'cat00916a', an: 'mit.001492509' }
      assert_response :success
      assert @response.body.include? 'Other title'
    end
  end

  test 'should be able to display rainbows' do
    get '/toggle/?feature=pride'
    VCR.use_cassette('record: rainbows', allow_playback_repeats: true) do
      get record_url, params: { db_source: 'cat00916a', an: 'mit.002613248' }
      assert_response :success
      assert_select 'div.reasons'
    end
  end

  test 'login is not shown when record AccessLevel > 2' do
    VCR.use_cassette('record: no access restriction',
                     allow_playback_repeats: true) do
      get record_url, params: { db_source: 'cat00916a', an: 'mit.001492509' }
      assert_response :success
      refute @response.body.include? 'Sign in for full access'
    end
  end

  test 'login is shown when record AccessLevel < 3' do
    VCR.use_cassette('record: access restriction',
                     allow_playback_repeats: true) do
      get record_url, params: { db_source: 'lah', an: '20123379364' }
      assert_response :success
      assert @response.body.include? 'Sign in for full access'
    end
  end

  test 'login is shown for pdflink on non-restricted records' do
    # NOTE: the record we pull back here no longer has the correct access level
    # for this test so the cassette has been manually modified to use 
    # access level 6 instead of the current record level of 2 to demonstrate
    # how the code works even if we can no longer find a valid record for tests
    VCR.use_cassette('record: pdflink unrestricted record',
                     allow_playback_repeats: true) do
      get record_url, params: { db_source: 'mdc', an: '25750248' }
      assert_response :success
      refute @response.body.include? 'Sign in for full access'
      assert @response.body.include? 'Sign in for access'
    end
  end

  test 'multiple item types can be shown in document info section' do
    VCR.use_cassette('record: multiple item types', allow_playback_repeats: true) do
      get record_url, params: { db_source: 'cat00916a', an: 'mit.002379994' }
      assert_select 'ul.list-moreinfo li', text: /Book; eBook/
    end
  end

  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ sidebar ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  test 'marc link is shown' do
    VCR.use_cassette('record: book', allow_playback_repeats: true) do
      get record_url, params: { db_source: 'cat00916a', an: 'mit.001492509' }
      assert_response :success
      assert_select "a[href=?]", "https://library.mit.edu/item/001492509",
        {text: 'Source record'}
    end
  end

  test 'eds link is shown' do
    VCR.use_cassette('record: book', allow_playback_repeats: true) do
      get record_url, params: { db_source: 'cat00916a', an: 'mit.001492509' }
      assert_response :success
      assert_select "a",
        {href: /search.ebscohost.com*db=cat00916a*AN=mit.001492509/,
         text: 'View in BartonPlus'}
    end
  end

  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ metatags ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  test 'DC.type is mapped' do
    VCR.use_cassette('record: article', allow_playback_repeats: true) do
      get record_url, params: { db_source: 'aci', an: '123877356' }
      assert_select('meta[name="DC.type"][content="Journal Article"]')
    end
  end
end
