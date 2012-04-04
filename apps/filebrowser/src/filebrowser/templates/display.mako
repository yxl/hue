## -*- coding: utf-8 -*-
## Licensed to Cloudera, Inc. under one
## or more contributor license agreements.  See the NOTICE file
## distributed with this work for additional information
## regarding copyright ownership.  Cloudera, Inc. licenses this file
## to you under the Apache License, Version 2.0 (the
## "License"); you may not use this file except in compliance
## with the License.  You may obtain a copy of the License at
##
##     http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
## See the License for the specific language governing permissions and
## limitations under the License.
<%!
  import datetime
  from django.template.defaultfilters import urlencode, stringformat, date, filesizeformat, time
  from filebrowser.views import truncate
  from desktop.views import commonheader, commonfooter
%>
<%
  path_enc = urlencode(path)
  dirname_enc = urlencode(view['dirname'])
  base_url = url('filebrowser.views.view', path=path_enc)
%>

${commonheader(truncate(filename)+' :: File Viewer', 'filebrowser')}



<div class="container-fluid">
	% if breadcrumbs:
		<div class="subnav">
		    <ul class="nav nav-pills">
		      <li><a href="${url('filebrowser.views.view', path=urlencode(path))}?default_to_home"><i class="icon-home"></i> Home</a></li>
		      <li>
				<ul class="hueBreadcrumb">
					% for breadcrumb_item in breadcrumbs:
					<li><a href="/filebrowser/view${breadcrumb_item['url']}">${breadcrumb_item['label']}</a> <span class="divider">/</span></li>
					% endfor
				</ul>
			  </li>
		    </ul>
		</div>
		<br/>
	%endif
</div>

<div class="container-fluid">
	<div class="row-fluid">
		<div class="span2">
			<div class="well sidebar-nav">
				<ul class="nav nav-list">
					<li class="nav-header">Actions</li>
					% if view['mode'] == "binary":
				        <li><a href="${base_url}?offset=${view['offset']}&length=${view['length']}&mode=text&compression=${view['compression']}">View As Text</a></li>
				      % endif
					  % if view['mode'] == "text":
				        <li><a href="${base_url}?offset=${view['offset']}&length=${view['length']}&mode=binary&compression=${view['compression']}">View As Binary</a></li>
				      % endif

				      % if view['compression'] != "gzip" and path.endswith('.gz'):
				        <li><a href="${base_url}?offset=0&length=2000&mode=${view['mode']}&compression=gzip">Preview As Gzip</a></li>
				      % endif

				      % if view['compression'] != "avro" and path.endswith('.avro'):
				        <li><a href="${base_url}?offset=0&length=2000&mode=${view['mode']}&compression=avro">Preview As Avro</a></li>
				      % endif

				      % if view['compression'] and view['compression'] != "none":
				        <li><a href="${base_url}?offset=0&length=2000&mode=${view['mode']}&compression=none">Stop preview</a></li>
				      % endif

				      % if editable and view['compression'] == "none":
				        <li><a href="${url('filebrowser.views.edit', path=path_enc)}">Edit File</a></li>
				      % endif
				       <li><a href="${url('filebrowser.views.download', path=path_enc)}">Download</a></li>
				       <li><a href="${url('filebrowser.views.view', path=dirname_enc)}">View File Location</a></li>
				       <li><a id="refreshBtn">Refresh</a></li>
					<li class="nav-header">Info</li>
					<li>
						<dl>
							<dt>Last Modified</dt>
				        	<dd>${date(datetime.datetime.fromtimestamp(stats['mtime']))} ${time(datetime.datetime.fromtimestamp(stats['mtime']))}</dd>
				        	<dt>User</dt>
				        	<dd>${stats['user']}</dd>
				        	<dt>Group</dt>
				        	<dd>${stats['group']}</dd>
				        	<dt>Size</dt>
				        	<dd>${stats['size']|filesizeformat}</dd>
				        	<dt>Mode</dt>
				        	<dd>${stringformat(stats['mode'], "o")}</dd>
						</dl>
					</li>
				</ul>

			</div>
		</div>
		<div class="span10">
			% if not view['compression'] or view['compression'] in ("none", "avro"):
			      <div class="pagination">
			        <%
			          base_url = url('filebrowser.views.view', path=path_enc)
			          if view['offset'] == 0:
			              first_class = "prev disabled"
			              prev_class = "disabled"
			              first_href = ""
			              prev_href = ""
			          else:
			              first_class = "prev"
			              prev_class = ""
			              first_href = "href=%s?offset=0&length=%d&compression=none title=1 - %d" %(base_url, view['length'], min(view['length'], stats['size']))
			              prev_href =  "href=%s?offset=%d&length=%d&compression=none title=%d - %d" %(base_url, max(0, view['offset']-view['length']), view['length'], max(0, view['offset']-view['length']) + 1, min(max(0, view['offset'] - view['length']) + view['length'], stats['size']))
			          if view['offset'] + view['length'] >= stats['size']:
			              next_class = "disabled"
			              last_class = "next disabled"
			              next_href = ""
			              last_href = ""
			          else:
			              next_class = ""
			              last_class = "next"
			              next_href = "href=%s?offset=%d&length=%d&compression=none title=%d - %d" %(base_url, view['offset'] + view['length'], view['length'], view['offset'] + view['length'] + 1, view['offset'] + (2 * view['length']))
			              last_href =  "href=%s?offset=%d&length=%d&compression=none title=%d - %d" %(base_url, stats['size']-(stats['size'] % view['length']), view['length'], stats['size']-(stats['size'] % view['length']) + 1, stats['size'])
			        %>
			        ###DEFINE REL
			        <ul>
			            <li class="${first_class}"><a ${first_href}>First Block</a></li>
			            <li class="${prev_class}"><a ${prev_href}>Previous Block</a></li>
			            <li class="${next_class}"><a ${next_href}>Next Block</a></li>
			            <li class="${last_class}"><a ${last_href}>Last Block</a></li>
			        </ul>

					<form action="${url('filebrowser.views.view', path=path_enc)}" method="GET" class="form-inline pull-right">
						<span>Viewing Bytes:</span>
						<input type="text" name="begin" value="${view['offset'] + 1}" class="input-mini" />
						-
						<input type="text" value="${view['end']}" name="end" class="input-mini" /> of
						<span>${stats['size']}</span>
						<span>(${view['length']} B block size)</span>
						% if view['mode']:
							<input type="hidden" name="mode" value="${view['mode']}"/>
						% endif
			        </form>

			      </div>

			    % endif
			%if 'contents' in view:
		      % if view['masked_binary_data']:
		      <div class="alert-message warning">Warning: some binary data has been masked out with '&#xfffd'.</div>
		      % endif
		    % endif
		      <div>
		      % if 'contents' in view:
		             <div><pre>${view['contents']|h}</pre></div>
		      % else:
		        <table>
		          % for offset, words, masked in view['xxd']:
		            <tr>
		              <td><tt>${stringformat(offset, "07x")}:&nbsp;</tt></td>
		            <td>
		              <tt>
		                % for word in words:
		                  % for byte in word:
		                    ${stringformat(byte, "02x")}
		                  % endfor
		                % endfor
		              </tt>
		            </td>
		            <td>
		              <tt>
		                &nbsp;&nbsp;${masked}
		              </tt>
		            </td>
		            </tr>
		          % endfor
		        </table>
		      % endif
		      </div>
			  % if not view['compression'] or view['compression'] in ("none", "avro"):
			      <div class="pagination">
			        <%
			          base_url = url('filebrowser.views.view', path=path_enc)
			          if view['offset'] == 0:
			              first_class = "prev disabled"
			              prev_class = "disabled"
			              first_href = ""
			              prev_href = ""
			          else:
			              first_class = "prev"
			              prev_class = ""
			              first_href = "href=%s?offset=0&length=%d&compression=none title=1 - %d" %(base_url, view['length'], min(view['length'], stats['size']))
			              prev_href =  "href=%s?offset=%d&length=%d&compression=none title=%d - %d" %(base_url, max(0, view['offset']-view['length']), view['length'], max(0, view['offset']-view['length']) + 1, min(max(0, view['offset'] - view['length']) + view['length'], stats['size']))
			          if view['offset'] + view['length'] >= stats['size']:
			              next_class = "disabled"
			              last_class = "next disabled"
			              next_href = ""
			              last_href = ""
			          else:
			              next_class = ""
			              last_class = "next"
			              next_href = "href=%s?offset=%d&length=%d&compression=none title=%d - %d" %(base_url, view['offset'] + view['length'], view['length'], view['offset'] + view['length'] + 1, view['offset'] + (2 * view['length']))
			              last_href =  "href=%s?offset=%d&length=%d&compression=none title=%d - %d" %(base_url, stats['size']-(stats['size'] % view['length']), view['length'], stats['size']-(stats['size'] % view['length']) + 1, stats['size'])
			        %>
			        ###DEFINE REL
			        <ul>
			            <li class="${first_class}"><a ${first_href}>First Block</a></li>
			            <li class="${prev_class}"><a ${prev_href}>Previous Block</a></li>
			            <li class="${next_class}"><a ${next_href}>Next Block</a></li>
			            <li class="${last_class}"><a ${last_href}>Last Block</a></li>
			        </ul>
			      </div>
			    % endif
		</div>
	</div>
</div>

	<script type="text/javascript" charset="utf-8">
		$(document).ready(function(){
			$("#refreshBtn").click(function(){
				window.location.reload();
			});
		});
	</script>
${commonfooter()}
